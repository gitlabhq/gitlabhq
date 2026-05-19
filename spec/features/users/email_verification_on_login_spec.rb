# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Email Verification On Login', :with_current_organization, :clean_gitlab_redis_rate_limiting, :js, feature_category: :instance_resiliency do
  include EmailHelpers

  let(:user) { create(:user) }
  let(:current_organization) { user.organization }
  let(:email_verification_required) { true }

  before do
    stub_application_setting(require_email_verification_on_account_locked: email_verification_required)
    stub_feature_flags(skip_require_email_verification: false)
    ActionMailer::Base.deliveries.clear
    allow(Gitlab::AppLogger).to receive(:info).and_call_original
    allow(Gitlab::ApplicationRateLimiter).to receive(:throttled?).and_call_original
  end

  describe 'when user login successfully without previous authentication event' do
    it 'does not lock the user or require email verification' do
      gitlab_sign_in(user)
      expect_no_email_verification
    end
  end

  describe 'when user has 2FA enabled' do
    let(:user) { create(:user, :two_factor) }

    it 'does not require email verification' do
      gitlab_sign_in(user, two_factor_auth: true)
      expect_no_email_verification
    end
  end

  describe 'when require_email_verification_on_account_locked is disabled' do
    let(:email_verification_required) { false }

    it 'does not require email verification' do
      gitlab_sign_in(user)
      expect_no_email_verification
    end
  end

  describe 'when failing to login the maximum allowed number of times' do
    before do
      user.update!(
        failed_attempts: RequireEmailVerification::MAXIMUM_ATTEMPTS - 1
      )
    end

    it 'locks at MAXIMUM_ATTEMPTS' do
      perform_enqueued_jobs do
        submit_sign_in_form_for(user, password: 'wrong_password')
        expect(page).to have_content(_('Invalid login or password.'))

        user.reload
        expect(user.locked_at).not_to be_nil
        expect(user.unlock_token).to be_nil # Only set after valid credentials
        expect(user.failed_attempts).to eq(RequireEmailVerification::MAXIMUM_ATTEMPTS)
      end
    end
  end

  describe 'after failing to login the maximum allowed number of times' do
    before do
      # Directly set the locked state
      user.update!(
        failed_attempts: RequireEmailVerification::MAXIMUM_ATTEMPTS,
        locked_at: Time.current
      )
    end

    describe 'login with valid credentials after account lock' do
      it 'triggers email verification process' do
        perform_enqueued_jobs do
          submit_sign_in_form_for(user)
          expect_verification_triggered(reason: 'new unlock token needed')
        end
      end

      it 'does not send duplicate verification emails on subsequent logins' do
        perform_enqueued_jobs do
          expect_no_duplicated_verification_email
        end
      end

      it 'shows success page with redirect after verification' do
        perform_enqueued_jobs do
          submit_sign_in_form_for(user)

          code = expect_instructions_email_and_extract_code
          perform_verification_with_code(code)
          expect_successful_verification
        end
      end
    end

    context 'when auto unlock time has passed' do
      before do
        travel User::UNLOCK_IN + 1.second
      end

      it 'does does not require email verification' do
        perform_enqueued_jobs do
          gitlab_sign_in(user)
          expect_no_email_verification
        end
      end
    end

    describe 'rate limiting password guessing' do
      before do
        # Rate-limit counter behaviour is covered in spec/requests/verifies_with_email_spec.rb.
        # Here we only verify the UI response when the limit is already exceeded.
        allow(Gitlab::ApplicationRateLimiter).to receive(:throttled?)
          .with(:user_sign_in, hash_including(scope: user)).and_return(true)
        submit_sign_in_form_for(user)
      end

      it 'shows an error message on on the login page' do
        expect(page).to have_current_path(new_user_session_path)
        expect(page).to have_content(format(s_('IdentityVerification|Maximum login attempts exceeded. '\
                                              'Wait %{interval} and try again.'), interval: '10 minutes'))
        expect(ActionMailer::Base.deliveries).to be_empty
      end
    end

    describe 'resending a new code' do
      before do
        # Cooldown UI is covered by component unit specs.
        stub_const('VerifiesWithEmailHelper::RESEND_COOLDOWN_PERIOD', 0)
      end

      it 'resends a new code' do
        perform_enqueued_jobs do
          submit_sign_in_form_for(user)
          expect(page).to have_content(s_('IdentityVerification|Help us protect your account'))

          code = expect_instructions_email_and_extract_code
          expect_log_message('Instructions Sent', reason: 'new unlock token needed')

          click_request_new_code_button
          expect(page).to have_content(s_('IdentityVerification|A new code is on its way. '\
                                          'If it doesn\'t arrive, check your spam folder.'))
          expect_log_message('Instructions Sent', reason: 'resend lock verification code')
          new_code = expect_instructions_email_and_extract_code
          expect(code).not_to eq(new_code)
        end
      end

      it 'rate limits resends' do
        # Counter behaviour is covered in spec/requests/verifies_with_email_spec.rb.
        # and_return(false, true) simulates: sign-in's send_rate_limited? check passes
        # (allowing the initial code to be sent), then the limit is exceeded on the next resend.
        allow(Gitlab::ApplicationRateLimiter).to receive(:throttled?)
          .with(:email_verification_code_send, hash_including(scope: user)).and_return(false, true)

        submit_sign_in_form_for(user)
        expect(page).to have_button s_('IdentityVerification|Resend code')
        click_request_new_code_button

        expect(page).to have_content format(s_("IdentityVerification|You've reached the maximum amount of resends. "\
                                               'Wait %{interval} and try again.'), interval: 'about 1 hour')
      end

      describe 'to a verified secondary email' do
        let(:secondary_email) { create(:email, :confirmed, user: user) }

        it 'resends a new code' do
          perform_enqueued_jobs do
            submit_sign_in_form_for(user)
            expect(page).to have_content(s_('IdentityVerification|Help us protect your account'))

            code_from_primary_email = expect_instructions_email_and_extract_code
            expect_log_message('Instructions Sent', reason: 'new unlock token needed')

            click_button s_('IdentityVerification|send a code to another address associated with this account')
            fill_in _('Email'), with: secondary_email.email

            click_button s_('IdentityVerification|Resend code')
            expect(page).to have_content(s_('IdentityVerification|A new code is on its way. '\
                                            'If it doesn\'t arrive, check your spam folder.'))
            expect_log_message('Instructions Sent', reason: 'resend lock verification code')

            code_from_secondary_email = expect_instructions_email_and_extract_code(email: secondary_email.email)
            expect(code_from_primary_email).not_to eq(code_from_secondary_email)
          end
        end
      end
    end

    describe 'resending a new code when an existing code expires' do
      it 'resends a new code' do
        perform_enqueued_jobs do
          submit_sign_in_form_for(user)
          code = expect_instructions_email_and_extract_code
          token_valid_for = Users::EmailVerification::ValidateTokenService::TOKEN_VALID_FOR_MINUTES + 1

          # Signing in again prompts for the code and sends a new one when the current code is expired
          travel_to(token_valid_for.minutes.from_now) do
            submit_sign_in_form_for(user)
            expect(page).to have_current_path(new_user_session_path)
            expect(page).to have_content(s_('IdentityVerification|Help us protect your account'))

            new_code = expect_instructions_email_and_extract_code
            expect_log_message('Instructions Sent', 2, reason: 'new unlock token needed')
            expect(code).not_to eq(new_code)
          end
        end
      end
    end

    describe 'verification errors' do
      it 'rate limits verifications' do
        # Counter behaviour is covered in spec/requests/verifies_with_email_spec.rb.
        # and_return(true, false) simulates: first attempt is rate-limited, then the
        # limit expires and subsequent attempts proceed normally.
        allow(Gitlab::ApplicationRateLimiter).to receive(:throttled?)
          .with(:email_verification, anything).and_return(true, false)

        perform_enqueued_jobs do
          submit_sign_in_form_for(user)
          code = expect_instructions_email_and_extract_code

          perform_verification_with_code('123456')

          expect(page).to have_content(
            format(s_("IdentityVerification|You've reached the maximum amount of tries. "\
                      'Wait %{interval} or send a new code and try again.'), interval: '10 minutes'))
          expect_log_message('Failed Attempt', reason: 'rate_limited')

          perform_verification_with_code(code)

          expect(page).to have_content(s_('IdentityVerification|Verification successful'))
          expect_log_message('Successful')
        end
      end

      it 'verifies invalid codes' do
        submit_sign_in_form_for(user)

        # Verify an invalid code
        perform_verification_with_code('123456')

        # Expect an error message
        expect(page).to have_content(s_('IdentityVerification|The code is incorrect. '\
                                        'Enter it again, or send a new code.'))
        expect_log_message('Failed Attempt', reason: 'invalid')
      end

      it 'verifies expired codes' do
        perform_enqueued_jobs do
          submit_sign_in_form_for(user)

          # Expect an instructions email to be sent with a code
          code = expect_instructions_email_and_extract_code

          # Wait for the code to expire before verifying
          travel Users::EmailVerification::ValidateTokenService::TOKEN_VALID_FOR_MINUTES.minutes + 1.second
          perform_verification_with_code(code)

          # Expect an error message
          expect(page).to have_content(
            s_('IdentityVerification|The code has expired. Send a new code and try again.')
          )
          expect_log_message('Failed Attempt', reason: 'expired')
        end
      end
    end

    describe 'when require_email_verification_on_account_locked is subsequently disabled' do
      let(:email_verification_required) { false }

      it 'does not show email verification but does not allow sign in while lock is active' do
        submit_sign_in_form_for(user)

        expect(page).to have_current_path(new_user_session_path)
        expect(page).not_to have_content(s_('IdentityVerification|Help us protect your account'))
      end

      context 'when the lock expires' do
        before do
          # With the setting disabled, override_devise_lockable? is false, so Devise's
          # standard unlock_in (10 minutes) applies instead of UNLOCK_IN (24 hours).
          travel Devise.unlock_in + 1.second
        end

        it 'does not require email verification' do
          gitlab_sign_in(user)
          expect_no_email_verification
        end
      end
    end
  end

  describe 'when a previous authentication event exists for another ip address' do
    before do
      create(:authentication_event, :successful, user: user, ip_address: '1.2.3.4')
    end

    context 'without 2fa enabled' do
      context 'with email_verification_required feature flag disabled' do
        let(:email_verification_required) { false }

        it 'does does not require email verification' do
          gitlab_sign_in(user)
          expect_no_email_verification
        end
      end

      context 'with email_verification_required feature flag enabled' do
        it 'triggers email verification process' do
          perform_enqueued_jobs do
            submit_sign_in_form_for(user)
            expect_verification_triggered(reason: 'sign in from untrusted IP address')
          end
        end

        it 'shows success page with redirect after verification' do
          perform_enqueued_jobs do
            submit_sign_in_form_for(user)
            code = expect_instructions_email_and_extract_code
            perform_verification_with_code(code)
            expect_successful_verification
          end
        end
      end
    end

    context 'with 2fa enabled' do
      let(:user) { create(:user, :two_factor) }

      it 'does does not require email verification' do
        gitlab_sign_in(user, two_factor_auth: true)
        expect_no_email_verification
      end
    end
  end

  describe 'when a previous authentication event exists for the same ip address' do
    before do
      create(:authentication_event, :successful, user: user)
    end

    it 'does does not require email verification' do
      gitlab_sign_in(user)
      expect_no_email_verification
    end
  end

  describe 'inconsistent states' do
    context 'when the feature flag is toggled off after being prompted for a verification token' do
      before do
        # Resend email cooldown UI is covered by component JS unit specs.
        stub_const('VerifiesWithEmailHelper::RESEND_COOLDOWN_PERIOD', 0)
        create(:authentication_event, :successful, user: user, ip_address: '1.2.3.4')
      end

      it 'token still works as expected' do
        perform_enqueued_jobs do
          submit_sign_in_form_for(user)
          expect(page).to have_content(s_('IdentityVerification|Help us protect your account'))
          code = expect_instructions_email_and_extract_code

          # toggle the application setting off
          stub_application_setting(require_email_verification_on_account_locked: false)

          # test verification using outdated token
          click_request_new_code_button
          new_code = expect_instructions_email_and_extract_code
          perform_verification_with_code(code)
          expect(page)
            .to have_content(s_('IdentityVerification|The code is incorrect. Enter it again, or send a new code.'))

          # force token expiration and test verification
          travel Users::EmailVerification::ValidateTokenService::TOKEN_VALID_FOR_MINUTES.minutes + 1.second
          perform_verification_with_code(new_code)
          expect(page).to have_content(
            s_('IdentityVerification|The code has expired. Send a new code and try again.')
          )

          # successful validation with valid token
          click_request_new_code_button
          code = expect_instructions_email_and_extract_code
          perform_verification_with_code(code)
          expect_successful_verification
        end
      end
    end

    context 'when the feature flag is toggled on after Devise sent unlock instructions' do
      let(:email_verification_required) { false }

      before do
        user.update!(failed_attempts: User.maximum_attempts - 1)
      end

      it 'the unlock link still works' do
        perform_enqueued_jobs do
          submit_sign_in_form_for(user, password: 'wrong_password')

          # The user is locked and unlock instructions are sent
          expect(page).to have_content(_('Invalid login or password.'))
        end

        user.reload
        expect(user.locked_at).not_to be_nil
        expect(user.unlock_token).not_to be_nil

        mail = wait_for('mail found for user') { find_email_for(user) }
        mail_to = mail&.to
        expect(mail_to).to match_array([user.email])
        expect(mail.subject).to eq('Unlock instructions')
        unlock_url = mail.body.parts.first.to_s[/http.*/]

        # toggle the application setting on
        stub_application_setting(require_email_verification_on_account_locked: true)

        # unlocking works as expected
        visit unlock_url

        expect(page).to have_current_path(new_user_session_path)
        expect(page).to have_content('Your account has been unlocked successfully')
        expect_user_to_be_unlocked

        gitlab_sign_in(user)
        expect(page).to have_current_path(root_path)
      end
    end
  end

  describe 'skip verification during warning period' do
    let(:today) { Time.zone.parse('2025-09-01') }

    before do
      stub_feature_flags(skip_require_email_verification: false)
      Feature.enable(:email_based_mfa, user)
      # email verification is skipped unless last_sign_in_at is populated
      user.update!(last_sign_in_at: today - 2.days)
      travel_to(today)
    end

    after do
      travel_back
    end

    context 'when user is not in email otp warning period' do
      let(:yesterday) { today - 1.day }
      let(:user) { create(:user, email_otp_required_after: yesterday) }

      it 'does not show skip for now button in email verification page' do
        submit_sign_in_form_for(user)
        expect_no_skip_for_now_button
      end
    end

    context 'when user is locked' do
      let(:user) { create(:user) }

      before do
        user.update!(unlock_token: 'token', locked_at: Time.current)
      end

      it 'does not show skip for now button in email verification page' do
        submit_sign_in_form_for(user)
        expect_no_skip_for_now_button
      end
    end

    context 'when user has a previous authentication event from a different IP address' do
      before do
        create(:authentication_event, :successful, user: user, ip_address: '1.2.3.4')
      end

      it 'does not show skip for now button in email verification page' do
        submit_sign_in_form_for(user)
        expect_no_skip_for_now_button
      end
    end

    context 'when user is not locked, has a safe IP address, and is in email otp warning period' do
      let(:tomorrow) { today + 1.day }
      let(:user) { create(:user, email_otp_required_after: tomorrow) }
      let(:parsed_date) { 'September 02, 2025' }
      let(:confirmation_msg) do
        "You can skip email verification for now. Starting on #{parsed_date}, email verification will be mandatory."
      end

      it 'user can skip email verification and will be reminded of the email otp required date' do
        submit_sign_in_form_for(user)

        expect(page).to have_content(s_('IdentityVerification|Help us protect your account'))
        expect(page).to have_button(s_('IdentityVerification|Skip for now'))

        click_button s_('IdentityVerification|Skip for now')

        expect(page).to have_content(confirmation_msg)
        expect(page).to have_current_path(users_skip_verification_confirmation_path)
        expect(page).to have_current_path(root_path)
      end

      it 'user can still choose to complete the email verification' do
        perform_enqueued_jobs do
          submit_sign_in_form_for(user)
          code = expect_instructions_email_and_extract_code
          perform_verification_with_code(code)
          expect(page).to have_current_path(root_path)
        end
      end
    end
  end

  private

  def expect_no_email_verification
    expect(page).to have_current_path(root_path)
    expect_user_to_be_unlocked
  end

  def expect_verification_triggered(reason: '')
    expect(page).to have_content(s_('IdentityVerification|Help us protect your account'))
    expect(page).to have_current_path(new_user_session_path)

    expect_log_message(message: "Account Locked: username=#{user.username}")
    expect_log_message('Instructions Sent', reason: reason)

    user.reload
    expect(user.locked_at).not_to be_nil
    expect(user.unlock_token).not_to be_nil

    expect(ActionMailer::Base.deliveries.size).to eq(1)
  end

  def expect_successful_verification
    expect(page).to have_content(s_('IdentityVerification|Verification successful'))
    expect(page).to have_current_path(users_successful_verification_path)
    expect(page).to have_selector("meta[http-equiv='refresh'][content='3; url=#{root_path}']", visible: :hidden)

    expect_log_message('Successful')
    expect_log_message(message: "Successful Login: username=#{user.username} "\
                                "ip=127.0.0.1 method=standard admin=false")

    expect_user_to_be_unlocked
  end

  def expect_no_duplicated_verification_email
    submit_sign_in_form_for(user)
    # First login triggers email
    wait_for('verification email delivered') do
      !ActionMailer::Base.deliveries.empty?
    end

    expect(ActionMailer::Base.deliveries.size).to eq(1)

    ActionMailer::Base.deliveries.clear
    submit_sign_in_form_for(user)

    expect(page).to have_current_path(new_user_session_path)
    expect(page).to have_content(s_('IdentityVerification|Help us protect your account'))

    # Second login should not send another email
    expect(ActionMailer::Base.deliveries.size).to eq(0)
  end

  def expect_log_message(event = nil, times = 1, reason: '', message: nil)
    expect(Gitlab::AppLogger).to have_received(:info)
      .exactly(times).times
      .with(message || hash_including(
        message: 'Email Verification',
        event: event,
        username: user.username,
        ip: '127.0.0.1',
        reason: reason
      ))
  end

  def expect_instructions_email_and_extract_code(email: nil)
    mail = wait_for('mail found for email || user') { find_email_for(email || user) }
    mail_to = mail&.to
    expect(mail_to).to match_array([email || user.email])
    expect(mail.subject).to eq(s_('IdentityVerification|Verify your identity'))
    code = mail.body.parts.first.to_s[/\d{#{Users::EmailVerification::GenerateTokenService::TOKEN_LENGTH}}/o]
    reset_delivered_emails!
    code
  end

  def expect_user_to_be_unlocked
    user.reload
    expect(user.locked_at).to be_nil
    expect(user.unlock_token).to be_nil
    expect(user.failed_attempts).to eq(0)
  end

  def expect_no_skip_for_now_button
    expect(page).to have_content(s_('IdentityVerification|Help us protect your account'))
    expect(page).not_to have_button(s_('IdentityVerification|Skip for now'))
  end

  def perform_verification_with_code(code)
    fill_in s_('IdentityVerification|Verification code'), with: code
    click_button s_('IdentityVerification|Verify code')
  end

  def click_request_new_code_button
    click_button s_('IdentityVerification|Resend code')
  end
end

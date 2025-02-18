# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Email Verification On Login', :clean_gitlab_redis_rate_limiting, :js, feature_category: :instance_resiliency do
  include EmailHelpers

  let_it_be_with_reload(:user) { create(:user) }
  let_it_be(:another_user) { create(:user) }
  let_it_be(:new_email) { build_stubbed(:user).email }

  let(:require_email_verification_enabled) { user }

  before do
    stub_feature_flags(require_email_verification: require_email_verification_enabled)
    stub_feature_flags(skip_require_email_verification: false)
  end

  shared_examples 'email verification required' do
    before do
      allow(Gitlab::AppLogger).to receive(:info)
    end

    it 'requires email verification before being able to access GitLab' do
      perform_enqueued_jobs do
        # When logging in
        gitlab_sign_in(user)
        expect_log_message(message: "Account Locked: username=#{user.username}")
        expect_log_message('Instructions Sent')

        # Expect the user to be locked and the unlock_token to be set
        user.reload
        expect(user.locked_at).not_to be_nil
        expect(user.unlock_token).not_to be_nil

        # Expect to see the verification form on the login page
        expect(page).to have_current_path(new_user_session_path)
        expect(page).to have_content(s_('IdentityVerification|Help us protect your account'))

        # Expect an instructions email to be sent with a code
        code = expect_instructions_email_and_extract_code

        # Signing in again prompts for the code and doesn't send a new one
        gitlab_sign_in(user)
        expect(page).to have_current_path(new_user_session_path)
        expect(page).to have_content(s_('IdentityVerification|Help us protect your account'))

        # Verify the code
        verify_code(code)
        expect_log_message('Successful')
        expect_log_message(message: "Successful Login: username=#{user.username} "\
                                    "ip=127.0.0.1 method=standard admin=false")

        # Expect the user to be unlocked
        expect_user_to_be_unlocked

        # Expect a confirmation page with a meta refresh tag for 3 seconds to the root
        expect(page).to have_current_path(users_successful_verification_path)
        expect(page).to have_content(s_('IdentityVerification|Verification successful'))
        expect(page).to have_selector("meta[http-equiv='refresh'][content='3; url=#{root_path}']", visible: false)
      end
    end

    describe 'resending a new code' do
      it 'resends a new code' do
        perform_enqueued_jobs do
          # When logging in
          gitlab_sign_in(user)

          # Expect an instructions email to be sent with a code
          code = expect_instructions_email_and_extract_code

          # Request a new code
          click_button s_('IdentityVerification|Resend code')
          expect(page).to have_content(s_('IdentityVerification|A new code has been sent.'))
          expect_log_message('Instructions Sent', 2)
          new_code = expect_instructions_email_and_extract_code

          # Verify the old code is different from the new code
          expect(code).not_to eq(new_code)
        end
      end

      it 'rate limits resends' do
        # When logging in
        gitlab_sign_in(user)

        # It shows a resend button
        expect(page).to have_button s_('IdentityVerification|Resend code')

        # Resend more than the rate limited amount of times
        10.times do
          click_button s_('IdentityVerification|Resend code')
        end

        # Expect an error alert
        expect(page).to have_content format(s_("IdentityVerification|You've reached the maximum amount of resends. "\
                                               'Wait %{interval} and try again.'), interval: 'about 1 hour')
      end

      describe 'to a verified secondary email' do
        let(:secondary_email) { create(:email, :confirmed, user: user) }

        it 'resends a new code' do
          perform_enqueued_jobs do
            gitlab_sign_in(user)

            code_from_primary_email = expect_instructions_email_and_extract_code

            click_button s_('IdentityVerification|send a code to another address associated with this account')

            fill_in _('Email'), with: secondary_email.email

            click_button s_('IdentityVerification|Resend code')

            expect(page).to have_content(s_('IdentityVerification|A new code has been sent.'))
            expect_log_message('Instructions Sent', 2)

            code_from_secondary_email = expect_instructions_email_and_extract_code(email: secondary_email.email)

            expect(code_from_primary_email).not_to eq(code_from_secondary_email)
          end
        end
      end
    end

    describe 'resending a new code when an existing code expires' do
      it 'resends a new code' do
        perform_enqueued_jobs do
          # When logging in
          gitlab_sign_in(user)

          # Expect an instructions email to be sent with a code
          code = expect_instructions_email_and_extract_code

          token_valid_for = Users::EmailVerification::ValidateTokenService::TOKEN_VALID_FOR_MINUTES + 1

          # Signing in again prompts for the code and sends a new one when the current code is expired
          travel_to(token_valid_for.minutes.from_now) do
            gitlab_sign_in(user)
            expect(page).to have_current_path(new_user_session_path)
            expect(page).to have_content(s_('IdentityVerification|Help us protect your account'))

            # Expect an instructions email to be sent with a new code
            new_code = expect_instructions_email_and_extract_code

            # Verify the old code is different from the new code
            expect(code).not_to eq(new_code)
          end
        end
      end
    end

    describe 'updating the email address' do
      it 'offers to update the email address' do
        perform_enqueued_jobs do
          # When logging in
          gitlab_sign_in(user)

          # Expect an instructions email to be sent with a code
          code = expect_instructions_email_and_extract_code

          # It shows an update email button
          expect(page).to have_button s_('IdentityVerification|Update email')

          # Click Update email button
          click_button s_('IdentityVerification|Update email')

          # Try to update with another user's email address
          fill_in _('Email'), with: another_user.email
          click_button s_('IdentityVerification|Update email')
          expect(page).to have_content('Email has already been taken')

          # Update to a unique email address
          fill_in _('Email'), with: new_email
          click_button s_('IdentityVerification|Update email')
          expect(page).to have_content(s_('IdentityVerification|A new code has been sent to ' \
                                          'your updated email address.'))
          expect_log_message('Instructions Sent', 2)

          new_code = expect_email_changed_notification_to_old_address_and_instructions_email_to_new_address

          # Verify the old code is different from the new code
          expect(code).not_to eq(new_code)
          verify_code(new_code)

          # Expect the user to be unlocked
          expect_user_to_be_unlocked
          expect_user_to_be_confirmed

          # When logging in again
          gitlab_sign_out
          gitlab_sign_in(user)

          # It does not show an update email button anymore
          expect(page).not_to have_button s_('IdentityVerification|Update email')
        end
      end
    end

    describe 'verification errors' do
      it 'rate limits verifications' do
        perform_enqueued_jobs do
          # When logging in
          gitlab_sign_in(user)

          # Expect an instructions email to be sent with a code
          code = expect_instructions_email_and_extract_code

          # Verify an invalid token more than the rate limited amount of times
          11.times do
            verify_code('123456')
          end

          # Expect an error message
          expect_log_message('Failed Attempt', reason: 'rate_limited')
          expect(page).to have_content(
            format(s_("IdentityVerification|You've reached the maximum amount of tries. "\
                      'Wait %{interval} or send a new code and try again.'), interval: '10 minutes'))

          # Wait for 10 minutes
          travel 10.minutes

          # Now it works again
          verify_code(code)
          expect_log_message('Successful')
        end
      end

      it 'verifies invalid codes' do
        # When logging in
        gitlab_sign_in(user)

        # Verify an invalid code
        verify_code('123456')

        # Expect an error message
        expect_log_message('Failed Attempt', reason: 'invalid')
        expect(page).to have_content(s_('IdentityVerification|The code is incorrect. '\
                                        'Enter it again, or send a new code.'))
      end

      it 'verifies expired codes' do
        perform_enqueued_jobs do
          # When logging in
          gitlab_sign_in(user)

          # Expect an instructions email to be sent with a code
          code = expect_instructions_email_and_extract_code

          # Wait for the code to expire before verifying
          travel Users::EmailVerification::ValidateTokenService::TOKEN_VALID_FOR_MINUTES.minutes + 1.second
          verify_code(code)

          # Expect an error message
          expect_log_message('Failed Attempt', reason: 'expired')
          expect(page).to have_content(s_('IdentityVerification|The code has expired. Send a new code and try again.'))
        end
      end
    end
  end

  shared_examples 'no email verification required' do |**login_args|
    it 'does not lock the user and redirects to the root page after logging in' do
      gitlab_sign_in(user, **login_args)

      expect_user_to_be_unlocked

      expect(page).to have_current_path(root_path)
    end
  end

  shared_examples 'no email verification required when 2fa enabled' do
    context 'when 2FA is enabled' do
      let_it_be(:user) { create(:user, :two_factor) }

      it_behaves_like 'no email verification required', two_factor_auth: true
    end

    context 'when the feature flag is disabled' do
      let(:require_email_verification_enabled) { false }

      it_behaves_like 'no email verification required'
    end
  end

  describe 'when failing to login the maximum allowed number of times' do
    before do
      RequireEmailVerification::MAXIMUM_ATTEMPTS.times do
        gitlab_sign_in(user, password: 'wrong_password')
      end
    end

    it 'locks the user, but does not set the unlock token', :aggregate_failures do
      user.reload
      expect(user.locked_at).not_to be_nil
      expect(user.unlock_token).to be_nil # The unlock token is only set after logging in with valid credentials
      expect(user.failed_attempts).to eq(RequireEmailVerification::MAXIMUM_ATTEMPTS)
    end

    it_behaves_like 'email verification required'
    it_behaves_like 'no email verification required when 2fa enabled'

    describe 'when waiting for the auto unlock time' do
      before do
        travel User::UNLOCK_IN + 1.second
      end

      it_behaves_like 'no email verification required'
    end
  end

  describe 'when no previous authentication event exists' do
    it_behaves_like 'no email verification required'
  end

  describe 'when a previous authentication event exists for another ip address' do
    before do
      create(:authentication_event, :successful, user: user, ip_address: '1.2.3.4')
    end

    it_behaves_like 'email verification required'
    it_behaves_like 'no email verification required when 2fa enabled'
  end

  describe 'when a previous authentication event exists for the same ip address' do
    before do
      create(:authentication_event, :successful, user: user)
    end

    it_behaves_like 'no email verification required'
  end

  describe 'rate limiting password guessing' do
    before do
      5.times { gitlab_sign_in(user, password: 'wrong_password') }
      gitlab_sign_in(user)
    end

    it 'shows an error message on on the login page' do
      expect(page).to have_current_path(new_user_session_path)
      expect(page).to have_content(format(s_('IdentityVerification|Maximum login attempts exceeded. '\
                                             'Wait %{interval} and try again.'), interval: '10 minutes'))
    end
  end

  describe 'inconsistent states' do
    context 'when the feature flag is toggled off after being prompted for a verification token' do
      before do
        create(:authentication_event, :successful, user: user, ip_address: '1.2.3.4')
      end

      it 'still accepts the token' do
        perform_enqueued_jobs do
          # The user is prompted for a verification code
          gitlab_sign_in(user)
          expect(page).to have_content(s_('IdentityVerification|Help us protect your account'))
          code = expect_instructions_email_and_extract_code

          # We toggle the feature flag off
          stub_feature_flags(require_email_verification: false)

          # Resending and veryfying the code work as expected
          click_button s_('IdentityVerification|Resend code')
          new_code = expect_instructions_email_and_extract_code

          verify_code(code)
          expect(page)
            .to have_content(s_('IdentityVerification|The code is incorrect. Enter it again, or send a new code.'))

          travel Users::EmailVerification::ValidateTokenService::TOKEN_VALID_FOR_MINUTES.minutes + 1.second

          verify_code(new_code)
          expect(page).to have_content(s_('IdentityVerification|The code has expired. Send a new code and try again.'))

          click_button s_('IdentityVerification|Resend code')
          another_code = expect_instructions_email_and_extract_code

          verify_code(another_code)
          expect_user_to_be_unlocked
          expect(page).to have_current_path(users_successful_verification_path)
        end
      end
    end

    context 'when the feature flag is toggled on after Devise sent unlock instructions' do
      let(:require_email_verification_enabled) { false }

      before do
        perform_enqueued_jobs do
          User.maximum_attempts.times do
            gitlab_sign_in(user, password: 'wrong_password')
          end
        end
      end

      it 'the unlock link still works' do
        # The user is locked and unlock instructions are sent
        expect(page).to have_content(_('Invalid login or password.'))
        user.reload
        expect(user.locked_at).not_to be_nil
        expect(user.unlock_token).not_to be_nil
        mail = find_email_for(user)

        expect(mail.to).to match_array([user.email])
        expect(mail.subject).to eq('Unlock instructions')
        unlock_url = mail.body.parts.first.to_s[/http.*/]

        # We toggle the feature flag on
        stub_feature_flags(require_email_verification: true)

        # Unlocking works as expected
        visit unlock_url
        expect_user_to_be_unlocked
        expect(page).to have_current_path(new_user_session_path)
        expect(page).to have_content('Your account has been unlocked successfully')

        gitlab_sign_in(user)
        expect(page).to have_current_path(root_path)
      end
    end
  end

  def expect_user_to_be_unlocked
    user.reload

    aggregate_failures do
      expect(user.locked_at).to be_nil
      expect(user.unlock_token).to be_nil
      expect(user.failed_attempts).to eq(0)
    end
  end

  def expect_user_to_be_confirmed
    aggregate_failures do
      expect(user.email).to eq(new_email)
      expect(user.unconfirmed_email).to be_nil
    end
  end

  def expect_email_changed_notification_to_old_address_and_instructions_email_to_new_address
    changed_email = ActionMailer::Base.deliveries[0]
    instructions_email = ActionMailer::Base.deliveries[1]

    expect(changed_email.to).to match_array([user.email])
    expect(changed_email.subject).to eq('Email Changed')

    expect(instructions_email.to).to match_array([new_email])
    expect(instructions_email.subject).to eq(s_('IdentityVerification|Verify your identity'))

    reset_delivered_emails!

    instructions_email.body.parts.first.to_s[/\d{#{Users::EmailVerification::GenerateTokenService::TOKEN_LENGTH}}/o]
  end

  def expect_instructions_email_and_extract_code(email: nil)
    mail = find_email_for(email || user)
    expect(mail.to).to match_array([email || user.email])
    expect(mail.subject).to eq(s_('IdentityVerification|Verify your identity'))
    code = mail.body.parts.first.to_s[/\d{#{Users::EmailVerification::GenerateTokenService::TOKEN_LENGTH}}/o]
    reset_delivered_emails!
    code
  end

  def verify_code(code)
    fill_in s_('IdentityVerification|Verification code'), with: code
    click_button s_('IdentityVerification|Verify code')
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
end

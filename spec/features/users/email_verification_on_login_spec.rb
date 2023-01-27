# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Email Verification On Login', :clean_gitlab_redis_rate_limiting, feature_category: :system_access do
  include EmailHelpers

  let_it_be(:user) { create(:user) }

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
        expect(page).to have_content('Help us protect your account')

        # Expect an instructions email to be sent with a code
        code = expect_instructions_email_and_extract_code

        # Signing in again prompts for the code and doesn't send a new one
        gitlab_sign_in(user)
        expect(page).to have_current_path(new_user_session_path)
        expect(page).to have_content('Help us protect your account')

        # Verify the code
        verify_code(code)
        expect_log_message('Successful')
        expect_log_message(message: "Successful Login: username=#{user.username} "\
                                    "ip=127.0.0.1 method=standard admin=false")

        # Expect the user to be unlocked
        expect_user_to_be_unlocked

        # Expect a confirmation page with a meta refresh tag for 3 seconds to the root
        expect(page).to have_current_path(users_successful_verification_path)
        expect(page).to have_content('Verification successful')
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
          click_link 'Resend code'
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
        expect(page).to have_link 'Resend code'

        # Resend more than the rate limited amount of times
        10.times do
          click_link 'Resend code'
        end

        # Expect the link to be gone
        expect(page).not_to have_link 'Resend code'

        # Wait for 1 hour
        travel 1.hour

        # Now it's visible again
        gitlab_sign_in(user)
        expect(page).to have_link 'Resend code'
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
          expect(page).to have_content("You've reached the maximum amount of tries. "\
                                       'Wait 10 minutes or send a new code and try again.')

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
        expect(page).to have_content('The code is incorrect. Enter it again, or send a new code.')
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
          expect(page).to have_content('The code has expired. Send a new code and try again.')
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

  shared_examples 'no email verification required when 2fa enabled or ff disabled' do
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
      # See comment in RequireEmailVerification::MAXIMUM_ATTEMPTS on why this is divided by 2
      (RequireEmailVerification::MAXIMUM_ATTEMPTS / 2).times do
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
    it_behaves_like 'no email verification required when 2fa enabled or ff disabled'

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
    it_behaves_like 'no email verification required when 2fa enabled or ff disabled'

    context 'when the check_ip_address_for_email_verification feature flag is disabled' do
      before do
        stub_feature_flags(check_ip_address_for_email_verification: false)
      end

      it_behaves_like 'no email verification required'
    end
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
      expect(page).to have_content('Maximum login attempts exceeded. Wait 10 minutes and try again.')
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
          click_link 'Resend code'
          new_code = expect_instructions_email_and_extract_code

          verify_code(code)
          expect(page)
            .to have_content(s_('IdentityVerification|The code is incorrect. Enter it again, or send a new code.'))

          travel Users::EmailVerification::ValidateTokenService::TOKEN_VALID_FOR_MINUTES.minutes + 1.second

          verify_code(new_code)
          expect(page).to have_content(s_('IdentityVerification|The code has expired. Send a new code and try again.'))

          click_link 'Resend code'
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
          (User.maximum_attempts / 2).times do
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

  def expect_instructions_email_and_extract_code
    mail = find_email_for(user)
    expect(mail.to).to match_array([user.email])
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
      .with(message || hash_including(message: 'Email Verification',
                                      event: event,
                                      username: user.username,
                                      ip: '127.0.0.1',
                                      reason: reason))
  end
end

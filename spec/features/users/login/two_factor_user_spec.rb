# frozen_string_literal: true

require 'spec_helper'

# Sign-in flows for users who already have 2FA enabled on their
# account: TOTP, WebAuthn, recovery codes, and the OAuth/SAML
# interactions that interact with 2FA.
#
# Add tests here when the precondition is "user has 2FA configured
# and is signing in". Tests where the *instance or group* requires
# 2FA but the user has not yet enrolled live in
# two_factor_required_spec.rb.

RSpec.describe 'Login', :with_current_organization, :clean_gitlab_redis_sessions, :aggregate_failures, feature_category: :system_access do
  include UserLoginHelper
  include SessionHelpers
  include Features::TwoFactorHelpers
  include EmailHelpers

  before do
    stub_authentication_activity_metrics(debug: true)
  end

  describe 'with two-factor authentication', :js do
    def enter_code(code, only_two_factor_webauthn_enabled: false)
      if only_two_factor_webauthn_enabled # rubocop:disable RSpec/AvoidConditionalStatements -- shared helper used for both WebAuthn-only and TOTP/WebAuthn paths; the branch reflects a real UI difference, not test flakiness
        # When this button is visible we know that the JavaScript functionality is ready.
        find_button(_('Try again?'))
        click_button _("Sign in via 2FA code")
      end

      fill_in _('Enter verification code'), with: code
      click_button _('Verify code')
    end

    shared_examples_for 'can login with recovery codes' do |only_two_factor_webauthn_enabled: false|
      context 'when using a backup code' do
        let(:codes) { user.generate_otp_backup_codes! }

        before do
          expect(codes.size).to eq 10 # rubocop:disable RSpec/ExpectInHook -- sanity check that the backup-code factory produced the expected count before the examples consume codes

          # Ensure the generated codes get saved
          user.save!(touch: false)
        end

        context 'with valid code' do
          it 'allows login' do
            expect(authentication_metrics)
              .to increment(:user_authenticated_counter)
              .and increment(:user_two_factor_authenticated_counter)

            enter_code(codes.sample, only_two_factor_webauthn_enabled: only_two_factor_webauthn_enabled)

            expect(page).to have_content('Welcome to GitLab')
            expect(page).to have_current_path root_path, ignore_query: true
          end

          it 'invalidates the used code' do
            expect(authentication_metrics)
              .to increment(:user_authenticated_counter)
              .and increment(:user_two_factor_authenticated_counter)

            size_before = user.reload.otp_backup_codes.size
            enter_code(codes.sample, only_two_factor_webauthn_enabled: only_two_factor_webauthn_enabled)
            expect(page).to have_content('Welcome to GitLab')
            expect(user.reload.otp_backup_codes.size).to eq(size_before - 1)
          end

          it 'invalidates backup codes twice in a row' do
            expect(authentication_metrics)
              .to increment(:user_authenticated_counter).twice
              .and increment(:user_two_factor_authenticated_counter).twice
              .and increment(:user_session_destroyed_counter)

            random_code = codes.delete(codes.sample)
            size_before = user.reload.otp_backup_codes.size
            enter_code(random_code, only_two_factor_webauthn_enabled: only_two_factor_webauthn_enabled)
            expect(page).to have_content('Welcome to GitLab')
            expect(user.reload.otp_backup_codes.size).to eq(size_before - 1)

            gitlab_sign_out(user)
            submit_sign_in_form_for(user)

            enter_code(codes.sample, only_two_factor_webauthn_enabled: only_two_factor_webauthn_enabled)
            expect(page).to have_content('Welcome to GitLab')
            expect(user.reload.otp_backup_codes.size).to eq(size_before - 2)
          end

          it 'triggers ActiveSession.cleanup for the user' do
            expect(authentication_metrics)
              .to increment(:user_authenticated_counter)
              .and increment(:user_two_factor_authenticated_counter)
            expect(ActiveSession).to receive(:cleanup).with(user).once.and_call_original

            enter_code(codes.sample, only_two_factor_webauthn_enabled: only_two_factor_webauthn_enabled)
          end
        end

        context 'with invalid code' do
          it 'blocks login' do
            # TODO, invalid two factor authentication does not increment
            # metrics / counters, see gitlab-org/gitlab-ce#49785

            code = codes.sample
            expect(user.invalidate_otp_backup_code!(code)).to be true

            user.save!(touch: false)
            expect(user.reload.otp_backup_codes.size).to eq 9

            enter_code(code, only_two_factor_webauthn_enabled: only_two_factor_webauthn_enabled)
            expect(page).to have_content('Invalid two-factor code.')
            expect(user.reload.failed_attempts).to eq(1)
          end
        end
      end
    end

    # Freeze time to prevent failures when time between code being entered and
    # validated greater than otp_allowed_drift
    context 'with valid username/password', :freeze_time do
      let(:user) { create(:user, :two_factor) }

      before do
        submit_sign_in_form_for(user, remember: true)
      end

      it 'does not show a "You are already signed in." error message' do
        expect(authentication_metrics)
          .to increment(:user_authenticated_counter)
          .and increment(:user_two_factor_authenticated_counter)

        enter_code(user.current_otp)
        expect(page).to have_content('Welcome to GitLab')
        expect(page).not_to have_content(I18n.t('devise.failure.already_authenticated'))
        expect_single_session_with_authenticated_ttl
      end

      it 'does not allow sign-in if the user password is updated before entering a one-time code' do
        expect(page).to have_content('Enter verification code')

        user.update!(password: User.random_password)
        enter_code(user.current_otp)

        expect(page).to have_content('An error occurred. Please sign in again.')
      end

      context 'when using a one-time code' do
        it 'allows login with valid code' do
          expect(authentication_metrics)
            .to increment(:user_authenticated_counter)
            .and increment(:user_two_factor_authenticated_counter)

          enter_code(user.current_otp)
          expect(page).to have_content('Welcome to GitLab')
          expect_single_session_with_authenticated_ttl
          expect(page).to have_current_path root_path, ignore_query: true
        end

        it 'persists remember_me value via hidden field' do
          expect(page).to have_field('user_remember_me', type: :hidden, with: '1')
        end

        it 'blocks login with invalid code' do
          # TODO invalid 2FA code does not generate any events
          # See gitlab-org/gitlab-ce#49785

          enter_code('foo')

          expect(page).to have_content('Invalid two-factor code')
        end

        it 'allows login with invalid code, then valid code' do
          expect(authentication_metrics)
            .to increment(:user_authenticated_counter)
            .and increment(:user_two_factor_authenticated_counter)

          enter_code('foo')
          expect(page).to have_content('Invalid two-factor code')

          enter_code(user.current_otp)
          expect(page).to have_content('Welcome to GitLab')
          expect_single_session_with_authenticated_ttl
          expect(page).to have_current_path root_path, ignore_query: true
        end

        it 'triggers ActiveSession.cleanup for the user' do
          expect(authentication_metrics)
            .to increment(:user_authenticated_counter)
            .and increment(:user_two_factor_authenticated_counter)
          expect(ActiveSession).to receive(:cleanup).with(user).once.and_call_original

          enter_code(user.current_otp)
        end
      end

      context 'when user with TOTP enabled' do
        let(:user) { create(:user, :two_factor) }

        include_examples 'can login with recovery codes'
      end

      context 'when user with only Webauthn enabled' do
        let(:user) { create(:user, :two_factor_via_webauthn, registrations_count: 1) }

        include_examples 'can login with recovery codes', only_two_factor_webauthn_enabled: true
      end
    end

    context 'when signing in with WebAuthn' do
      let(:user) { create(:user, :two_factor_via_webauthn, organization: current_organization) }

      before do
        visit new_user_session_path
        fill_in 'user_login', with: user.username
        fill_in 'user_password', with: user.password
        click_button 'Sign in'
      end

      context 'when falling back to email OTP' do
        context 'when email_based_mfa feature flag is disabled' do
          before do
            stub_feature_flags(email_based_mfa: false)
          end

          it 'does not show the email OTP fallback footer' do
            expect(page).not_to have_content('Having trouble signing in?')
            expect(page).not_to have_link('send code to email address')
          end
        end

        context 'when email_based_mfa feature flag is enabled' do
          # we will not be testing different email_otp_required_after values
          # since this is covered in the unit test level
          context 'when user has email_otp_required_after set to past date' do
            let(:user) { create(:user, :two_factor_via_webauthn, email_otp_required_after: 1.day.ago) }

            context 'when WebAuthn authentication fails' do
              before do
                ActionMailer::Base.deliveries.clear
              end

              it 'shows the email OTP fallback footer with helpful links' do
                expect(page).to have_content('Having trouble signing in?')
                expect(page).to have_link('Enter recovery code')
                expect(page).to have_button('send code to email address')

                expect(authentication_metrics)
                  .to increment(:user_authenticated_counter)
                  .and increment(:user_session_override_counter)

                verify_email_otp_fallback_workflow(user)
              end
            end
          end
        end
      end
    end

    context 'when logging in via OAuth' do
      let(:user) { create(:omniauth_user, :two_factor, extern_uid: 'my-uid', provider: 'saml') }
      let(:mock_saml_response) do
        File.read('spec/fixtures/authentication/saml_response.xml')
      end

      before do
        stub_omniauth_saml_config(
          enabled: true,
          auto_link_saml_user: true,
          allow_single_sign_on: ['saml'],
          providers: [mock_saml_config_with_upstream_two_factor_authn_contexts]
        )
      end

      it 'displays the remember me checkbox' do
        visit new_user_session_path

        expect(page).to have_field('js-remember-me-omniauth')
      end

      it 'appends URL fragment to all the oauth forms', :js do
        visit new_user_session_path(anchor: '65')

        within '.js-oauth-login' do
          expect(page).to have_selector('form[action$="?redirect_fragment=65"]')

          check _('Remember me')
          expect(page).to have_selector('form[action$="?redirect_fragment=65&remember_me=1"]')
        end
      end

      context 'when remember me is not enabled' do
        before do
          stub_application_setting(remember_me_enabled: false)
        end

        it 'does not display the remember me checkbox' do
          visit new_user_session_path

          expect(page).not_to have_field('js-remember-me-omniauth')
        end
      end

      context 'when authn_context is worth two factors' do
        let(:mock_saml_response) do
          File.read('spec/fixtures/authentication/saml_response.xml')
            .gsub(
              'urn:oasis:names:tc:SAML:2.0:ac:classes:Password',
              'urn:oasis:names:tc:SAML:2.0:ac:classes:SecondFactorOTPSMS'
            )
        end

        it 'signs user in without prompting for second factor' do
          # TODO, OAuth authentication does not fire events,
          # see gitlab-org/gitlab-ce#49786

          expect(authentication_metrics)
            .to increment(:user_authenticated_counter)
          expect(ActiveSession).to receive(:cleanup).with(user).once.and_call_original

          sign_in_using_saml!
          expect(page).to have_content('Welcome to GitLab')
          expect_single_session_with_authenticated_ttl
          expect(page).not_to have_content(_('Enter verification code'))
          expect(page).to have_current_path root_path, ignore_query: true
        end
      end

      # Freeze time to prevent failures when time between code being entered and
      # validated greater than otp_allowed_drift
      context 'when two factor authentication is required', :freeze_time do
        it 'shows 2FA prompt after OAuth login' do
          expect(authentication_metrics)
            .to increment(:user_authenticated_counter)
            .and increment(:user_two_factor_authenticated_counter)
          expect(ActiveSession).to receive(:cleanup).with(user).once.and_call_original

          sign_in_using_saml!

          expect(page).to have_content('Enter verification code')

          enter_code(user.current_otp)
          expect(page).to have_content('Welcome to GitLab')
          expect_single_session_with_authenticated_ttl
          expect(page).to have_current_path root_path, ignore_query: true
        end
      end

      def sign_in_using_saml!
        gitlab_sign_in_via('saml', user, 'my-uid', mock_saml_response)
      end
    end
  end
end

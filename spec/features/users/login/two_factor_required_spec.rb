# frozen_string_literal: true

require 'spec_helper'

# Sign-in flows where the *instance or group* requires 2FA but the
# signing-in user has not yet enrolled (grace-period UX, redirect to
# enrollment page, fallbacks, etc.).
#
# Add tests here when the precondition is "2FA is required at the
# global or group level". Tests where the user already has 2FA on
# their account live in two_factor_user_spec.rb.

RSpec.describe 'Login', :with_current_organization, :clean_gitlab_redis_sessions, :aggregate_failures, feature_category: :system_access do
  include UserLoginHelper
  include SessionHelpers
  include Features::TwoFactorHelpers
  include EmailHelpers

  before do
    stub_authentication_activity_metrics(debug: true)
  end

  describe 'with required two-factor authentication enabled', :js do
    let(:user) { create(:user, :with_namespace, organization: current_organization) }

    #  TODO: otp_grace_period_started_at

    context 'with global setting' do
      before do
        stub_application_setting(require_two_factor_authentication: true)
      end

      context 'with grace period defined' do
        before do
          stub_application_setting(two_factor_grace_period: 48)
        end

        context 'when within the grace period' do
          it 'redirects to two-factor configuration page' do
            expect(authentication_metrics)
              .to increment(:user_authenticated_counter)

            gitlab_sign_in(user)

            expect(page).to have_current_path profile_two_factor_auth_path, ignore_query: true
            expect(page).to have_content(
              'The global settings require you to enable Two-Factor Authentication for your account. ' \
                'You need to do this before '
            )
          end

          it 'allows skipping two-factor configuration' do
            expect(authentication_metrics)
              .to increment(:user_authenticated_counter)

            gitlab_sign_in(user)

            expect(page).to have_current_path profile_two_factor_auth_path, ignore_query: true
            click_link _('Configure it later')
            expect(page).to have_current_path root_path, ignore_query: true
          end
        end

        context 'when after the grace period' do
          let(:user) do
            create(:user, :with_namespace, organization: current_organization,
              otp_grace_period_started_at: 9999.hours.ago)
          end

          it 'redirects to two-factor configuration page' do
            expect(authentication_metrics)
              .to increment(:user_authenticated_counter)

            gitlab_sign_in(user)

            expect(page).to have_current_path profile_two_factor_auth_path, ignore_query: true
            expect(page).to have_content(
              'The global settings require you to enable Two-Factor Authentication for your account.'
            )
          end

          it 'disallows skipping two-factor configuration' do
            expect(authentication_metrics)
              .to increment(:user_authenticated_counter)

            gitlab_sign_in(user)

            expect(page).to have_current_path profile_two_factor_auth_path, ignore_query: true
            expect(page).not_to have_link(_('Configure it later'))
          end
        end
      end

      context 'without grace period defined' do
        before do
          stub_application_setting(two_factor_grace_period: 0)
        end

        it 'redirects to two-factor configuration page' do
          expect(authentication_metrics)
            .to increment(:user_authenticated_counter)

          gitlab_sign_in(user)

          expect(page).to have_current_path profile_two_factor_auth_path, ignore_query: true
          expect(page).to have_content(
            'The global settings require you to enable Two-Factor Authentication for your account.'
          )
        end
      end
    end

    context 'with group setting' do
      before do
        group1 = create :group, name: 'Group 1', require_two_factor_authentication: true
        group1.add_member(user, GroupMember::DEVELOPER)
        group2 = create :group, name: 'Group 2', require_two_factor_authentication: true
        group2.add_member(user, GroupMember::DEVELOPER)
      end

      context 'with grace period defined' do
        before do
          stub_application_setting(two_factor_grace_period: 48)
        end

        context 'when within the grace period' do
          it 'redirects to two-factor configuration page', :freeze_time do
            expect(authentication_metrics)
              .to increment(:user_authenticated_counter)

            gitlab_sign_in(user)

            expect(page).to have_current_path profile_two_factor_auth_path, ignore_query: true
            expect(page).to have_content(
              'The group settings for Group 1 and Group 2 require you to enable ' \
                'Two-Factor Authentication for your account. ' \
                'You can leave Group 1 and leave Group 2. ' \
                'You need to do this ' \
                'before ' \
                "#{(Time.zone.now + 2.days).strftime('%a, %d %b %Y %H:%M:%S %z')}"
            )
          end

          it 'allows skipping two-factor configuration' do
            expect(authentication_metrics)
              .to increment(:user_authenticated_counter)

            gitlab_sign_in(user)

            expect(page).to have_current_path profile_two_factor_auth_path, ignore_query: true
            click_link _('Configure it later')
            expect(page).to have_current_path root_path, ignore_query: true
          end
        end

        context 'when after the grace period' do
          let(:user) do
            create(:user, :with_namespace, organization: current_organization,
              otp_grace_period_started_at: 9999.hours.ago)
          end

          it 'redirects to two-factor configuration page' do
            expect(authentication_metrics)
              .to increment(:user_authenticated_counter)

            gitlab_sign_in(user)

            expect(page).to have_current_path profile_two_factor_auth_path, ignore_query: true
            expect(page).to have_content(
              'The group settings for Group 1 and Group 2 require you to enable ' \
                'Two-Factor Authentication for your account.'
            )
          end

          it 'disallows skipping two-factor configuration' do
            expect(authentication_metrics)
              .to increment(:user_authenticated_counter)

            gitlab_sign_in(user)

            expect(page).to have_current_path profile_two_factor_auth_path, ignore_query: true
            expect(page).not_to have_link(_('Configure it later'))
          end
        end
      end

      context 'without grace period defined' do
        before do
          stub_application_setting(two_factor_grace_period: 0)
        end

        it 'redirects to two-factor configuration page' do
          expect(authentication_metrics)
            .to increment(:user_authenticated_counter)

          gitlab_sign_in(user)

          expect(page).to have_current_path profile_two_factor_auth_path, ignore_query: true
          expect(page).to have_content(
            'The group settings for Group 1 and Group 2 require you to enable ' \
              'Two-Factor Authentication for your account. ' \
              'You can leave Group 1 and leave Group 2.'
          )
        end
      end
    end

    context 'when falling back to email OTP from TOTP', :js do
      let(:user) { create(:user, :two_factor, email_otp_required_after: 1.day.ago) }

      before do
        ActionMailer::Base.deliveries.clear
        submit_sign_in_form_for(user)
        expect(page).to have_content('Enter verification code') # rubocop:disable RSpec/ExpectInHook -- this assertion is the Capybara waiter ensuring the OTP form is rendered before the examples run
      end

      it 'sends email OTP and shows verification form when button clicked' do
        expect(page).to have_link('Enter recovery code')
        expect(page).to have_button('send code to email address')

        expect(authentication_metrics)
          .to increment(:user_authenticated_counter)
          .and increment(:user_session_override_counter)

        verify_email_otp_fallback_workflow(user)
      end

      context 'when email_based_mfa ff is disabled' do
        before do
          stub_feature_flags(email_based_mfa: false)
        end

        it 'does not show email OTP fallback when feature is disabled' do
          visit new_user_session_path
          submit_sign_in_form_for(user)
          expect(page).not_to have_button('send code to email address')
        end
      end
    end

    context 'when user has both WebAuthn and TOTP enabled', :js do
      let(:user) do
        create(:user,
          :two_factor,
          :two_factor_via_webauthn,
          email_otp_required_after: 1.day.ago
        )
      end

      before do
        ActionMailer::Base.deliveries.clear
        visit new_user_session_path
        submit_sign_in_form_for(user)
        click_button 'Sign in via 2FA code'
      end

      it 'allows switching to TOTP and using email OTP fallback' do
        expect(page).to have_content('Enter verification code')

        # Email OTP fallback should be available
        expect(page).to have_link('Enter recovery code')
        expect(page).to have_button('send code to email address')

        expect(authentication_metrics)
          .to increment(:user_authenticated_counter)
          .and increment(:user_session_override_counter)

        verify_email_otp_fallback_workflow(user)
      end

      it 'can still use TOTP code after switching from WebAuthn' do
        expect(authentication_metrics)
          .to increment(:user_authenticated_counter)
          .and increment(:user_two_factor_authenticated_counter)

        # Enter TOTP code
        fill_in 'user_otp_attempt', with: user.current_otp
        click_button 'Verify code'

        expect(page).to have_content('Welcome to GitLab')
        expect(page).to have_current_path root_path, ignore_query: true
      end
    end
  end
end

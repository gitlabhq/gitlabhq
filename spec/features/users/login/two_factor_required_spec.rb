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
              'The global settings require you to enable two-factor authentication (2FA) for your account. ' \
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
              'The global settings require you to enable two-factor authentication (2FA) for your account.'
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
            'The global settings require you to enable two-factor authentication (2FA) for your account.'
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
              'One or more groups require you to add 2FA to your account. Choose your preferred method below ' \
                'or review and leave groups to continue using your account.'
            )
            expect(page).to have_content('You need to do this before')

            within('.gl-alert-actions') do
              expect(page).to have_link('Configure it later')
            end

            find('summary', text: _('Review and leave groups')).click
            expect(page).to have_link('Group 1')
            expect(page).to have_link('Group 2')
            expect(page).to have_link('Leave group', count: 2)
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
              'One or more groups require you to add 2FA to your account. Choose your preferred method below ' \
                'or review and leave groups to continue using your account.'
            )
            expect(page).not_to have_link('Configure it later')

            find('summary', text: _('Review and leave groups')).click
            expect(page).to have_link('Group 1')
            expect(page).to have_link('Group 2')
            expect(page).to have_link('Leave group', count: 2)
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
            'One or more groups require you to add 2FA to your account. Choose your preferred method below ' \
              'or review and leave groups to continue using your account.'
          )

          find('summary', text: _('Review and leave groups')).click
          expect(page).to have_link('Group 1')
          expect(page).to have_link('Group 2')
          expect(page).to have_link('Leave group', count: 2)
        end
      end
    end

    context 'when falling back to email OTP from TOTP', :js do
      let(:user) { create(:user, :two_factor, email_otp_required_after: 1.day.ago) }
      let(:email_otp_enabled) { false }

      # The email-OTP fallback renders the Vue screen with two_factor_vue on and the legacy
      # HAML footer with it off; assert and drive each UI's own affordances.
      with_and_without_ff(:two_factor_vue) do
        before do
          ActionMailer::Base.deliveries.clear
          stub_application_setting(email_otp_enabled: email_otp_enabled)
          submit_sign_in_form_for(user)
          expect(page).to have_button(s_('TwoFactorAuth|Verify code')) # rubocop:disable RSpec/ExpectInHook -- this assertion is the Capybara waiter ensuring the OTP form is rendered before the examples run
        end

        it 'does not show email OTP fallback when feature is disabled' do
          expect_email_otp_fallback_absent(user)
        end

        context 'when email_otp_enabled application setting is enabled' do
          let(:email_otp_enabled) { true }

          it 'sends email OTP and shows verification form when button clicked' do
            expect_email_otp_fallback_available(user)

            expect(authentication_metrics)
              .to increment(:user_authenticated_counter)
              .and increment(:user_session_override_counter)

            verify_email_otp_fallback_workflow(user)
          end
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

      let(:email_otp_enabled) { false }

      with_and_without_ff(:two_factor_vue) do
        before do
          ActionMailer::Base.deliveries.clear
          stub_application_setting(email_otp_enabled: email_otp_enabled)
          visit new_user_session_path
          submit_sign_in_form_for(user)
          # WebAuthn is the default for this user; switch to the TOTP screen. The
          # authenticator-app-button testid is shared by both UIs.
          use_otp_fallback
        end

        context 'when email_otp_enabled application setting is enabled' do
          let(:email_otp_enabled) { true }

          it 'allows switching to TOTP and using email OTP fallback' do
            expect(page).to have_button(s_('TwoFactorAuth|Verify code'))

            # Email OTP fallback should be available
            expect_email_otp_fallback_available(user)

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
            click_button s_('TwoFactorAuth|Verify code')

            expect(page).to have_content('Welcome to GitLab')
            expect(page).to have_current_path root_path, ignore_query: true
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

# Sign-in flows where the instance enforces terms of service and the
# user has not yet accepted them. Includes the interactions with 2FA
# enforcement and password expiry, since the "terms must be accepted
# first" requirement layers on top of those flows.
#
# Add tests here when the precondition is "terms are enforced and the
# user has not accepted them"; the test should describe how the
# terms-acceptance step interleaves with the rest of the login flow.

RSpec.describe 'Login', :with_current_organization, :clean_gitlab_redis_sessions, :aggregate_failures, feature_category: :system_access do
  include TermsHelper
  include UserLoginHelper
  include SessionHelpers
  include Features::TwoFactorHelpers

  before do
    stub_authentication_activity_metrics(debug: true)
  end

  context 'when terms are enforced', :js do
    let(:user) { create(:user, :with_namespace, organization: current_organization) }

    before do
      enforce_terms
    end

    it 'asks to accept the terms on first login' do
      expect(authentication_metrics)
        .to increment(:user_authenticated_counter)

      visit new_user_session_path

      gitlab_sign_in(user)

      expect_to_be_on_terms_page
      click_button 'Accept terms'

      expect(page).to have_current_path(root_path, ignore_query: true)
      expect(page).not_to have_content(I18n.t('devise.failure.already_authenticated'))
    end

    it 'does not ask for terms when the user already accepted them' do
      expect(authentication_metrics)
        .to increment(:user_authenticated_counter)

      accept_terms(user)

      visit new_user_session_path

      gitlab_sign_in(user)

      expect(page).to have_current_path(root_path, ignore_query: true)
    end

    context 'when 2FA is required for the user' do
      before do
        group = create(:group, require_two_factor_authentication: true)
        group.add_developer(user)
      end

      context 'when the user did not enable 2FA' do
        it 'asks to set 2FA before asking to accept the terms' do
          expect(authentication_metrics)
            .to increment(:user_authenticated_counter)

          visit new_user_session_path

          gitlab_sign_in(user)

          expect_to_be_on_terms_page
          click_button 'Accept terms'

          expect(page).to have_current_path(profile_two_factor_auth_path, ignore_query: true)

          # Use the secret shown on the page to generate the OTP that will be entered.
          # This detects issues wherein a new secret gets generated after the
          # page is shown.
          expect(page).to have_button(_('Register authenticator'))

          click_button _('Register authenticator')
          otp_secret = page.find('.two-factor-secret').text.gsub('Key:', '').delete(' ')
          current_otp = ROTP::TOTP.new(otp_secret).now
          click_button _('Cancel')

          otp_authenticator_registration_and_copy_codes(current_otp, user.password)

          expect(page).to have_current_path(profile_two_factor_auth_path, ignore_query: true)
          expect(page).to have_content(_('2FA setup complete!'))
        end
      end

      context 'when the user already enabled 2FA' do
        before do
          user.update!(otp_required_for_login: true, otp_secret: User.generate_otp_secret(32))
        end

        it 'asks the user to accept the terms' do
          expect(authentication_metrics)
            .to increment(:user_authenticated_counter)
            .and increment(:user_two_factor_authenticated_counter)

          visit new_user_session_path

          gitlab_sign_in(user, two_factor_auth: true)

          expect_to_be_on_terms_page
          click_button 'Accept terms'

          expect(page).to have_current_path(root_path, ignore_query: true)
        end
      end
    end

    context 'when the users password is expired' do
      before do
        user.update!(password_expires_at: Time.zone.parse('2018-05-08 11:29:46 UTC'))
      end

      it 'asks the user to accept the terms before setting a new password' do
        expect(authentication_metrics)
          .to increment(:user_authenticated_counter)

        visit new_user_session_path

        gitlab_sign_in(user)

        expect_to_be_on_terms_page
        click_button 'Accept terms'

        expect(page).to have_current_path(new_user_settings_password_path, ignore_query: true)

        new_password = User.random_password

        fill_in 'user_password', with: user.password
        fill_in 'user_new_password', with: new_password
        fill_in 'user_password_confirmation', with: new_password
        click_button 'Update password'

        expect(page).to have_content('Password successfully changed')
      end
    end

    context 'when the user does not have an email configured' do
      let_it_be(:username) { generate(:username) }
      let(:user) do
        create(:omniauth_user, :with_namespace, organization: current_organization,
          extern_uid: 'my-uid', provider: 'saml',
          email: "temp-email-for-oauth-#{username}@gitlab.localhost")
      end

      before do
        stub_feature_flags(edit_user_profile_vue: false)
        stub_omniauth_saml_config(enabled: true, auto_link_saml_user: true, allow_single_sign_on: ['saml'],
          providers: [mock_saml_config])
      end

      it 'asks the user to accept the terms before setting an email' do
        expect(authentication_metrics)
        .to increment(:user_authenticated_counter)

        gitlab_sign_in_via('saml', user, 'my-uid')

        expect_to_be_on_terms_page
        click_button 'Accept terms'

        expect(page).to have_current_path(user_settings_profile_path, ignore_query: true)

        # Wait until the form has been initialized
        has_testid?('form-ready')

        fill_in 'Email', with: 'hello@world.com'

        click_button 'Update profile settings'

        expect(page).to have_content('Profile was successfully updated')
        expect(user.reload).to have_attributes({ unconfirmed_email: 'hello@world.com' })
      end
    end
  end
end

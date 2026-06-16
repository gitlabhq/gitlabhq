# frozen_string_literal: true

require 'spec_helper'

# Sign-in flows for users authenticated via an external provider that
# does not need a second factor: auto-sign-in-with-provider (SAML),
# and JWT-based identity linking.
#
# Add tests here when the precondition is "the user authenticates via
# an external identity provider" and the test is *not* about 2FA
# interactions (those live in two_factor_user_spec.rb).

RSpec.describe 'Login', :with_current_organization, :clean_gitlab_redis_sessions, :aggregate_failures, feature_category: :system_access do
  include UserLoginHelper
  include SessionHelpers

  before do
    stub_authentication_activity_metrics(debug: true)
  end

  describe 'with auto_sign_in_with_provider enabled' do
    before do
      stub_omniauth_saml_config(
        enabled: true,
        auto_sign_in_with_provider: 'saml',
        allow_single_sign_on: ['saml']
      )

      allow_next_instance_of(ActionDispatch::Routing::RoutesProxy) do |instance|
        allow(instance).to receive(:user_saml_omniauth_authorize_path)
          .and_return('/api/graphql?my_fake_idp') # A dummy page where we can do a POST request
      end
    end

    it 'redirects to the identity provider', :js do
      visit new_user_session_path

      expect(page.current_url).to end_with('/api/graphql?my_fake_idp')
    end

    it 'does not redirect to the identity provider when auto_sign_in=false is set', :js do
      visit new_user_session_path(auto_sign_in: 'false')

      expect(page).to have_button('Sign in')
    end
  end

  context 'when signing in with JWT', :js do
    let_it_be(:user) { create(:user, :with_namespace, organization: current_organization) }

    before do
      stub_omniauth_config(providers: [{ name: 'jwt', label: 'JWT', args: {} }])
      stub_omniauth_provider('jwt')
      mock_auth_hash('jwt', 'jwt_uid', user.email)
    end

    context 'when the user does not have a JWT identity' do
      context 'when the user is already signed in' do
        before do
          expect(authentication_metrics).to increment(:user_authenticated_counter) # rubocop:disable RSpec/ExpectInHook -- message-expectation mock setup for the metric, must be installed before the sign-in fires

          gitlab_sign_in(user)
        end

        it 'requires the user to authorize linking the JWT identity' do
          visit user_jwt_omniauth_callback_path

          expect(page).to have_current_path new_user_settings_identities_path, ignore_query: true
          expect(page).to have_content(
            format(
              _('Allow %{strongOpen}%{provider}%{strongClose} to sign you in?'),
              strongOpen: '',
              strongClose: '',
              provider: 'JWT')
          )

          click_button 'Authorize'

          expect(page).to have_current_path profile_account_path
          expect(page).to have_content(_('Authentication method updated'))

          expect(user.identities.last.provider).to eq('jwt')
          expect(user.identities.last.extern_uid).to eq('jwt_uid')
        end

        it 'does not link the identity when the user clicks Cancel' do
          visit user_jwt_omniauth_callback_path

          expect(page).to have_current_path new_user_settings_identities_path, ignore_query: true
          expect(page).to have_content(
            format(
              _('Allow %{strongOpen}%{provider}%{strongClose} to sign you in?'),
              strongOpen: '',
              strongClose: '',
              provider: 'JWT')
          )

          click_link 'Cancel'

          expect(page).to have_current_path profile_account_path
          expect(page).not_to have_content(_('Authentication method updated'))

          expect(user.identities).to be_empty
        end
      end
    end
  end
end

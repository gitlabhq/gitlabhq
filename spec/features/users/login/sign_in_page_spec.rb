# frozen_string_literal: true

require 'spec_helper'

# Tests for the sign-in *page itself* (not the sign-in flow): which
# tabs and panes render, CSP headers, body-class helpers, and the
# remember-me checkbox visibility under various provider configs.
#
# Add tests here when the precondition is "we render the sign-in page
# in <some configuration>" and the test does not actually submit
# credentials.

RSpec.describe 'Login', :with_current_organization, :clean_gitlab_redis_sessions, :aggregate_failures, feature_category: :system_access do
  include UserLoginHelper
  include SessionHelpers

  before do
    stub_authentication_activity_metrics(debug: true)
  end

  describe 'with OneTrust authentication' do
    before do
      stub_config(extra: { one_trust_id: SecureRandom.uuid })
    end

    it 'has proper Content-Security-Policy headers' do
      visit root_path

      expect(response_headers['Content-Security-Policy']).to include('https://cdn.cookielaw.org https://*.onetrust.com')
    end
  end

  describe 'UI tabs and panes' do
    context 'when no defaults are changed' do
      it 'does not render any tabs' do
        visit new_user_session_path

        expect_no_tabs
      end

      it 'renders logo', :js do
        visit new_user_session_path

        image = find('img.js-portrait-logo-detection')
        expect(image['class']).to include('gl-h-10')
      end

      it 'renders link to sign up path' do
        visit new_user_session_path

        expect(page.body).to have_link('Register now', href: new_user_registration_path)
      end
    end

    context 'when signup is disabled' do
      before do
        stub_application_setting(signup_enabled: false)

        visit new_user_session_path
      end

      it 'does not render any tabs' do
        expect_no_tabs
      end

      it 'does not render link to sign up path' do
        visit new_user_session_path

        expect(page.body).not_to have_link('Register now', href: new_user_registration_path)
      end
    end

    context 'when ldap is enabled' do
      include LdapHelpers

      let(:provider) { 'ldapmain' }
      let(:ldap_server_config) do
        {
          'label' => 'Main LDAP',
          'provider_name' => provider,
          'attributes' => {},
          'encryption' => 'plain',
          'uid' => 'uid',
          'base' => 'dc=example,dc=com'
        }
      end

      before do
        stub_ldap_setting(enabled: true)
        allow(::Gitlab::Auth::Ldap::Config).to receive_messages(enabled: true, servers: [ldap_server_config])
        allow(Gitlab::Auth::OAuth::Provider).to receive_messages(providers: [provider.to_sym])

        Ldap::OmniauthCallbacksController.define_providers!
        Rails.application.reload_routes!

        allow_next_instance_of(ActionDispatch::Routing::RoutesProxy) do |instance|
          allow(instance).to receive(:"user_#{provider}_omniauth_callback_path")
            .and_return("/users/auth/#{provider}/callback")
        end
      end

      it 'correctly renders tabs and panes' do
        visit new_user_session_path

        expect_tab_pane_correctness(['Main LDAP', 'Standard'])
      end

      it 'appends URL fragment to all the non oauth forms', :js do
        visit new_user_session_path(anchor: '65')

        within '.js-non-oauth-login' do
          expect(page).to have_selector('#ldapmain form[action$="#65"]')
          expect(page).to have_selector('#login-pane form[action$="#65"]', visible: :hidden)
          expect(page).to have_selector('form[data-testid="passkey-form"][action$="#65"]', visible: :hidden)
        end
      end

      it 'renders link to sign up path' do
        visit new_user_session_path

        expect(page.body).to have_link('Register now', href: new_user_registration_path)
      end

      it 'displays the remember me checkbox' do
        visit new_user_session_path

        expect_remember_me_in_tab(ldap_server_config['label'])
      end

      context 'when remember me is not enabled' do
        before do
          stub_application_setting(remember_me_enabled: false)
        end

        it 'does not display the remember me checkbox' do
          visit new_user_session_path

          expect_remember_me_not_in_tab(ldap_server_config['label'])
        end
      end
    end

    context 'when crowd is enabled' do
      before do
        allow(Gitlab::Auth::OAuth::Provider).to receive_messages(providers: [:crowd])
        stub_application_setting(crowd_enabled: true)

        Ldap::OmniauthCallbacksController.define_providers!
        Rails.application.reload_routes!

        allow_next_instance_of(ActionDispatch::Routing::RoutesProxy) do |instance|
          allow(instance).to receive(:user_crowd_omniauth_authorize_path)
            .and_return("/users/auth/crowd/callback")
        end
      end

      it 'correctly renders tabs and panes' do
        visit new_user_session_path

        expect_tab_pane_correctness(%w[Crowd Standard])
      end

      it 'displays the remember me checkbox' do
        visit new_user_session_path

        expect_remember_me_in_tab(_('Crowd'))
      end

      context 'when remember me is not enabled' do
        before do
          stub_application_setting(remember_me_enabled: false)
        end

        it 'does not display the remember me checkbox' do
          visit new_user_session_path

          expect_remember_me_not_in_tab(_('Crowd'))
        end
      end
    end
  end

  describe 'Client helper classes and flags' do
    it 'adds client browser and platform classes to page body' do
      visit root_path
      expect(find('body')[:class]).to include('gl-browser-generic')
      expect(find('body')[:class]).to include('gl-platform-other')
    end
  end
end

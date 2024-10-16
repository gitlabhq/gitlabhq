# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'OAuth Login', :allow_forgery_protection, feature_category: :system_access do
  include DeviseHelpers

  def enter_code(code)
    fill_in 'user_otp_attempt', with: code
    click_button 'Verify code'
  end

  def stub_omniauth_config(provider)
    OmniAuth.config.add_mock(provider, OmniAuth::AuthHash.new(provider: provider.to_s, uid: "12345"))
    stub_omniauth_provider(provider)
  end

  providers = [:github, :bitbucket, :gitlab, :google_oauth2,
               :auth0, :salesforce, :alicloud]

  around do |example|
    with_omniauth_full_host { example.run }
  end

  def login_with_provider(provider, enter_two_factor: false, additional_info: {})
    login_via(provider.to_s, user, uid, remember_me: remember_me, additional_info: additional_info)
    enter_code(user.current_otp) if enter_two_factor
  end

  providers.each do |provider|
    context "when the user logs in using the #{provider} provider", :js do
      let(:uid) { 'my-uid' }
      let(:remember_me) { false }
      let(:user) { create(:omniauth_user, extern_uid: uid, provider: provider.to_s) }
      let(:two_factor_user) { create(:omniauth_user, :two_factor, extern_uid: uid, provider: provider.to_s) }

      provider == :salesforce ? let(:additional_info) { { extra: { email_verified: true } } } : let(:additional_info) { {} }

      before do
        stub_omniauth_config(provider)
        expect(ActiveSession).to receive(:cleanup).with(user).at_least(:once).and_call_original
      end

      context 'when two-factor authentication is disabled' do
        it 'logs the user in' do
          login_with_provider(provider, additional_info: additional_info)

          expect(page).to have_current_path root_path, ignore_query: true
        end
      end

      context 'when two-factor authentication is enabled' do
        let(:user) { two_factor_user }

        it 'logs the user in' do
          login_with_provider(provider, additional_info: additional_info, enter_two_factor: true)

          expect(page).to have_current_path root_path, ignore_query: true
        end

        it 'when bypass-two-factor is enabled' do
          allow(Gitlab.config.omniauth).to receive_messages(allow_bypass_two_factor: true)
          login_via(provider.to_s, user, uid, remember_me: false, additional_info: additional_info)
          expect(page).to have_current_path root_path, ignore_query: true
        end

        it 'when bypass-two-factor is disabled' do
          allow(Gitlab.config.omniauth).to receive_messages(allow_bypass_two_factor: false)
          login_with_provider(provider, enter_two_factor: true, additional_info: additional_info)
          expect(page).to have_current_path root_path, ignore_query: true
        end
      end

      context 'when "remember me" is checked' do
        let(:remember_me) { true }

        context 'when two-factor authentication is disabled' do
          it 'remembers the user after a browser restart' do
            login_with_provider(provider, additional_info: additional_info)

            clear_browser_session

            visit(root_path)
            expect(page).to have_current_path root_path, ignore_query: true
          end
        end

        context 'when two-factor authentication is enabled' do
          let(:user) { two_factor_user }

          it 'remembers the user after a browser restart' do
            login_with_provider(provider, enter_two_factor: true, additional_info: additional_info)

            clear_browser_session

            visit(root_path)
            expect(page).to have_current_path root_path, ignore_query: true
          end
        end
      end

      context 'when "remember me" is not checked' do
        context 'when two-factor authentication is disabled' do
          it 'does not remember the user after a browser restart' do
            login_with_provider(provider, additional_info: additional_info)

            clear_browser_session

            visit(root_path)
            expect(page).to have_current_path new_user_session_path, ignore_query: true
          end
        end

        context 'when two-factor authentication is enabled' do
          let(:user) { two_factor_user }

          it 'does not remember the user after a browser restart' do
            login_with_provider(provider, enter_two_factor: true, additional_info: additional_info)

            clear_browser_session

            visit(root_path)
            expect(page).to have_current_path new_user_session_path, ignore_query: true
          end
        end
      end
    end
  end

  context 'using GitLab as an OAuth provider' do
    let_it_be(:user) { create(:user) }

    let(:redirect_uri) { Gitlab::Routing.url_helpers.root_url }

    # We can't use let_it_be to set the redirect_uri when creating the
    # record as the host / port depends on whether or not the spec uses
    # JS.
    let(:application) do
      create(:oauth_application, scopes: 'api', redirect_uri: redirect_uri, confidential: true)
    end

    let(:params) do
      {
        response_type: 'code',
        client_id: application.uid,
        redirect_uri: redirect_uri,
        state: 'state'
      }
    end

    before do
      sign_in(user)

      create(:organization, :default)
      create(:oauth_access_token, application: application, resource_owner_id: user.id, scopes: 'api')
    end

    context 'when JS is enabled', :js do
      it 'includes the fragment in the redirect if it is simple' do
        visit "#{Gitlab::Routing.url_helpers.oauth_authorization_url(params)}#a_test-hash"

        expect(page).to have_current_path("#{Gitlab::Routing.url_helpers.root_url}#a_test-hash", ignore_query: true)
      end

      it 'does not include the fragment if it contains forbidden characters' do
        visit "#{Gitlab::Routing.url_helpers.oauth_authorization_url(params)}#a_test-hash."

        expect(page).to have_current_path(Gitlab::Routing.url_helpers.root_url, ignore_query: true)
      end
    end

    context 'when JS is disabled' do
      it 'provides a basic HTML page including a link without the fragment' do
        visit "#{Gitlab::Routing.url_helpers.oauth_authorization_url(params)}#a_test-hash"

        expect(page).to have_current_path(oauth_authorization_path(params))
        expect(page).to have_selector("a[href^='#{redirect_uri}']")
      end
    end
  end
end

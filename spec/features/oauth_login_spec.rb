require 'spec_helper'

feature 'OAuth Login', feature: true, js: true do
  def enter_code(code)
    fill_in 'user_otp_attempt', with: code
    click_button 'Verify code'
  end

  def provider_config(provider)
    if provider == :saml
      OpenStruct.new(
        name: 'saml', label: 'saml',
        args: {
          assertion_consumer_service_url: 'https://localhost:3443/users/auth/saml/callback',
          idp_cert_fingerprint: '26:43:2C:47:AF:F0:6B:D0:07:9C:AD:A3:74:FE:5D:94:5F:4E:9E:52',
          idp_sso_target_url: 'https://idp.example.com/sso/saml',
          issuer: 'https://localhost:3443/',
          name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:transient'
        }
      )
    else
      OpenStruct.new(name: provider.to_s, app_id: 'app_id', app_secret: 'app_secret')
    end
  end

  def stub_omniauth_config(provider)
    OmniAuth.config.add_mock(provider, OmniAuth::AuthHash.new({ provider: provider.to_s, uid: "12345" }))
    Rails.application.env_config['devise.mapping'] = Devise.mappings[:user]
    Rails.application.env_config["omniauth.auth"] = OmniAuth.config.mock_auth[provider]
  end

  providers = [:github, :twitter, :bitbucket, :gitlab, :google_oauth2,
               :facebook, :authentiq, :cas3, :auth0]

  before do
    OmniAuth.config.full_host = ->(request) { request['REQUEST_URI'].sub(/#{request['REQUEST_PATH']}.*/, '') }

    messages = {
      enabled: true,
      allow_single_sign_on: providers.map(&:to_s),
      auto_link_saml_user: true,
      providers: providers.map { |provider| provider_config(provider) }
    }

    allow(Gitlab.config.omniauth).to receive_messages(messages)
  end

  # context 'logging in via OAuth' do
  #   def saml_config

  #   end
  #   def stub_omniauth_config(messages)
  #     Rails.application.env_config['devise.mapping'] = Devise.mappings[:user]
  #     Rails.application.routes.disable_clear_and_finalize = true
  #     Rails.application.routes.draw do
  #       post '/users/auth/saml' => 'omniauth_callbacks#saml'
  #     end
  #     allow(Gitlab::OAuth::Provider).to receive_messages(providers: [:saml], config_for: saml_config)
  #     allow(Gitlab.config.omniauth).to receive_messages(messages)
  #     expect_any_instance_of(Object).to receive(:omniauth_authorize_path).with(:user, "saml").and_return('/users/auth/saml')
  #   end
  #   it 'shows 2FA prompt after OAuth login' do
  #     stub_omniauth_config(enabled: true, auto_link_saml_user: true, allow_single_sign_on: ['saml'], providers: [saml_config])
  #     user = create(:omniauth_user, :two_factor, extern_uid: 'my-uid', provider: 'saml')
  #     login_via('saml', user, 'my-uid')
  #     expect(page).to have_content('Two-Factor Authentication')
  #     enter_code(user.current_otp)
  #     expect(current_path).to eq root_path
  #   end
  # end

  providers.each do |provider|
    context "when the user logs in using the #{provider} provider" do
      context "when two-factor authentication is disabled" do
        it 'logs the user in' do
          stub_omniauth_config(provider)
          user = create(:omniauth_user, extern_uid: 'my-uid', provider: provider.to_s)
          login_via(provider.to_s, user, 'my-uid')

          expect(current_path).to eq root_path
        end
      end

      context "when two-factor authentication is enabled" do
        it 'logs the user in' do
          stub_omniauth_config(provider)
          user = create(:omniauth_user, :two_factor, extern_uid: 'my-uid', provider: provider.to_s)
          login_via(provider.to_s, user, 'my-uid')

          enter_code(user.current_otp)
          expect(current_path).to eq root_path
        end
      end

      context 'when "remember me" is checked' do
        context "when two-factor authentication is disabled" do
          it 'remembers the user after a browser restart' do
            stub_omniauth_config(provider)
            user = create(:omniauth_user, extern_uid: 'my-uid', provider: provider.to_s)
            login_via(provider.to_s, user, 'my-uid', remember_me: true)

            restart_browser

            visit(root_path)
            expect(current_path).to eq root_path
          end
        end

        context "when two-factor authentication is enabled" do
          it 'remembers the user after a browser restart' do
            stub_omniauth_config(provider)
            user = create(:omniauth_user, :two_factor, extern_uid: 'my-uid', provider: provider.to_s)
            login_via(provider.to_s, user, 'my-uid', remember_me: true)
            enter_code(user.current_otp)

            restart_browser

            visit(root_path)
            expect(current_path).to eq root_path
          end
        end
      end

      context 'when "remember me" is not checked' do
        context "when two-factor authentication is disabled" do
          it 'does not remember the user after a browser restart' do
            stub_omniauth_config(provider)
            user = create(:omniauth_user, extern_uid: 'my-uid', provider: provider.to_s)
            login_via(provider.to_s, user, 'my-uid', remember_me: false)

            restart_browser

            visit(root_path)
            expect(current_path).to eq new_user_session_path
          end
        end

        context "when two-factor authentication is enabled" do
          it 'remembers the user after a browser restart' do
            stub_omniauth_config(provider)
            user = create(:omniauth_user, :two_factor, extern_uid: 'my-uid', provider: provider.to_s)
            login_via(provider.to_s, user, 'my-uid', remember_me: false)
            enter_code(user.current_otp)

            restart_browser

            visit(root_path)
            expect(current_path).to eq new_user_session_path
          end
        end
      end
    end
  end
end

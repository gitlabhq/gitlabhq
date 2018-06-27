require 'spec_helper'

feature 'OAuth Login', :js, :allow_forgery_protection do
  include DeviseHelpers

  def enter_code(code)
    fill_in 'user_otp_attempt', with: code
    click_button 'Verify code'
  end

  def stub_omniauth_config(provider)
    OmniAuth.config.add_mock(provider, OmniAuth::AuthHash.new(provider: provider.to_s, uid: "12345"))
    stub_omniauth_provider(provider)
  end

  providers = [:github, :twitter, :bitbucket, :gitlab, :google_oauth2,
               :facebook, :cas3, :auth0, :authentiq]

  before(:all) do
    # The OmniAuth `full_host` parameter doesn't get set correctly (it gets set to something like `http://localhost`
    # here), and causes integration tests to fail with 404s. We set the `full_host` by removing the request path (and
    # anything after it) from the request URI.
    @omniauth_config_full_host = OmniAuth.config.full_host
    OmniAuth.config.full_host = ->(request) { request['REQUEST_URI'].sub(/#{request['REQUEST_PATH']}.*/, '') }
  end

  after(:all) do
    OmniAuth.config.full_host = @omniauth_config_full_host
  end

  def login_with_provider(provider, enter_two_factor: false)
    login_via(provider.to_s, user, uid, remember_me: remember_me)
    enter_code(user.current_otp) if enter_two_factor
  end

  providers.each do |provider|
    context "when the user logs in using the #{provider} provider" do
      let(:uid) { 'my-uid' }
      let(:remember_me) { false }
      let(:user) { create(:omniauth_user, extern_uid: uid, provider: provider.to_s) }
      let(:two_factor_user) { create(:omniauth_user, :two_factor, extern_uid: uid, provider: provider.to_s) }

      before do
        stub_omniauth_config(provider)
      end

      context 'when two-factor authentication is disabled' do
        it 'logs the user in' do
          login_with_provider(provider)

          expect(current_path).to eq root_path
        end
      end

      context 'when two-factor authentication is enabled' do
        let(:user) { two_factor_user }

        it 'logs the user in' do
          login_with_provider(provider, enter_two_factor: true)

          expect(current_path).to eq root_path
        end
      end

      context 'when "remember me" is checked' do
        let(:remember_me) { true }

        context 'when two-factor authentication is disabled' do
          it 'remembers the user after a browser restart' do
            login_with_provider(provider)

            clear_browser_session

            visit(root_path)
            expect(current_path).to eq root_path
          end
        end

        context 'when two-factor authentication is enabled' do
          let(:user) { two_factor_user }

          it 'remembers the user after a browser restart' do
            login_with_provider(provider, enter_two_factor: true)

            clear_browser_session

            visit(root_path)
            expect(current_path).to eq root_path
          end
        end
      end

      context 'when "remember me" is not checked' do
        context 'when two-factor authentication is disabled' do
          it 'does not remember the user after a browser restart' do
            login_with_provider(provider)

            clear_browser_session

            visit(root_path)
            expect(current_path).to eq new_user_session_path
          end
        end

        context 'when two-factor authentication is enabled' do
          let(:user) { two_factor_user }

          it 'does not remember the user after a browser restart' do
            login_with_provider(provider, enter_two_factor: true)

            clear_browser_session

            visit(root_path)
            expect(current_path).to eq new_user_session_path
          end
        end
      end
    end
  end
end

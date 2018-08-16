require 'spec_helper'

describe OmniauthCallbacksController, type: :controller do
  include LoginHelpers

  describe 'omniauth' do
    let(:user) { create(:omniauth_user, extern_uid: extern_uid, provider: provider) }

    before do
      mock_auth_hash(provider.to_s, extern_uid, user.email)
      stub_omniauth_provider(provider, context: request)
    end

    context 'when the user is on the last sign in attempt' do
      let(:extern_uid) { 'my-uid' }

      before do
        user.update(failed_attempts: User.maximum_attempts.pred)
        subject.response = ActionDispatch::Response.new
      end

      context 'when using a form based provider' do
        let(:provider) { :ldap }

        it 'locks the user when sign in fails' do
          allow(subject).to receive(:params).and_return(ActionController::Parameters.new(username: user.username))
          request.env['omniauth.error.strategy'] = OmniAuth::Strategies::LDAP.new(nil)

          subject.send(:failure)

          expect(user.reload).to be_access_locked
        end
      end

      context 'when using a button based provider' do
        let(:provider) { :github }

        it 'does not lock the user when sign in fails' do
          request.env['omniauth.error.strategy'] = OmniAuth::Strategies::GitHub.new(nil)

          subject.send(:failure)

          expect(user.reload).not_to be_access_locked
        end
      end
    end

    context 'strategies' do
      context 'github' do
        let(:extern_uid) { 'my-uid' }
        let(:provider) { :github }

        it 'allows sign in' do
          post provider

          expect(request.env['warden']).to be_authenticated
        end

        shared_context 'sign_up' do
          let(:user) { double(email: 'new@example.com') }

          before do
            stub_omniauth_setting(block_auto_created_users: false)
          end
        end

        context 'sign up' do
          include_context 'sign_up'

          it 'is allowed' do
            post provider

            expect(request.env['warden']).to be_authenticated
          end
        end

        context 'when OAuth is disabled' do
          before do
            stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
            settings = Gitlab::CurrentSettings.current_application_settings
            settings.update(disabled_oauth_sign_in_sources: [provider.to_s])
          end

          it 'prevents login via POST' do
            post provider

            expect(request.env['warden']).not_to be_authenticated
          end

          it 'shows warning when attempting login' do
            post provider

            expect(response).to redirect_to new_user_session_path
            expect(flash[:alert]).to eq('Signing in using GitHub has been disabled')
          end

          it 'allows linking the disabled provider' do
            user.identities.destroy_all # rubocop: disable DestroyAll
            sign_in(user)

            expect { post provider }.to change { user.reload.identities.count }.by(1)
          end

          context 'sign up' do
            include_context 'sign_up'

            it 'is prevented' do
              post provider

              expect(request.env['warden']).not_to be_authenticated
            end
          end
        end
      end

      context 'auth0' do
        let(:extern_uid) { '' }
        let(:provider) { :auth0 }

        it 'does not allow sign in without extern_uid' do
          post 'auth0'

          expect(request.env['warden']).not_to be_authenticated
          expect(response.status).to eq(302)
          expect(controller).to set_flash[:alert].to('Wrong extern UID provided. Make sure Auth0 is configured correctly.')
        end
      end
    end
  end

  describe '#saml' do
    let(:user) { create(:omniauth_user, :two_factor, extern_uid: 'my-uid', provider: 'saml') }
    let(:mock_saml_response) { File.read('spec/fixtures/authentication/saml_response.xml') }
    let(:saml_config) { mock_saml_config_with_upstream_two_factor_authn_contexts }

    before do
      stub_omniauth_saml_config({ enabled: true, auto_link_saml_user: true, allow_single_sign_on: ['saml'],
                                  providers: [saml_config] })
      mock_auth_hash('saml', 'my-uid', user.email, mock_saml_response)
      request.env["devise.mapping"] = Devise.mappings[:user]
      request.env['omniauth.auth'] = Rails.application.env_config['omniauth.auth']
      post :saml, params: { SAMLResponse: mock_saml_response }
    end

    context 'when worth two factors' do
      let(:mock_saml_response) do
        File.read('spec/fixtures/authentication/saml_response.xml')
            .gsub('urn:oasis:names:tc:SAML:2.0:ac:classes:Password', 'urn:oasis:names:tc:SAML:2.0:ac:classes:SecondFactorIGTOKEN')
      end

      it 'expects user to be signed_in' do
        expect(request.env['warden']).to be_authenticated
      end
    end

    context 'when not worth two factors' do
      it 'expects user to provide second factor' do
        expect(response).to render_template('devise/sessions/two_factor')
        expect(request.env['warden']).not_to be_authenticated
      end
    end
  end
end

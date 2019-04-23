# frozen_string_literal: true

require 'spec_helper'

describe OmniauthCallbacksController, type: :controller do
  include LoginHelpers

  describe 'omniauth' do
    let(:user) { create(:omniauth_user, extern_uid: extern_uid, provider: provider) }

    before do
      @original_env_config_omniauth_auth = mock_auth_hash(provider.to_s, +extern_uid, user.email)
      stub_omniauth_provider(provider, context: request)
    end

    after do
      Rails.application.env_config['omniauth.auth'] = @original_env_config_omniauth_auth
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

    context 'when sign in fails' do
      include RoutesHelpers

      let(:extern_uid) { 'my-uid' }
      let(:provider) { :saml }

      def stub_route_as(path)
        allow(@routes).to receive(:generate_extras) { [path, []] }
      end

      it 'calls through to the failure handler' do
        request.env['omniauth.error'] = OneLogin::RubySaml::ValidationError.new("Fingerprint mismatch")
        request.env['omniauth.error.strategy'] = OmniAuth::Strategies::SAML.new(nil)
        stub_route_as('/users/auth/saml/callback')

        ForgeryProtection.with_forgery_protection do
          post :failure
        end

        expect(flash[:alert]).to match(/Fingerprint mismatch/)
      end
    end

    context 'when a redirect fragment is provided' do
      let(:provider) { :jwt }
      let(:extern_uid) { 'my-uid' }

      before do
        request.env['omniauth.params'] = { 'redirect_fragment' => 'L101' }
      end

      context 'when a redirect url is stored' do
        it 'redirects with fragment' do
          post provider, session: { user_return_to: '/fake/url' }

          expect(response).to redirect_to('/fake/url#L101')
        end
      end

      context 'when a redirect url with a fragment is stored' do
        it 'redirects with the new fragment' do
          post provider, session: { user_return_to: '/fake/url#replaceme' }

          expect(response).to redirect_to('/fake/url#L101')
        end
      end

      context 'when no redirect url is stored' do
        it 'does not redirect with the fragment' do
          post provider

          expect(response.redirect?).to be true
          expect(response.location).not_to include('#L101')
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

        context 'when user has no linked provider' do
          let(:user) { create(:user) }

          before do
            sign_in user
          end

          it 'links identity' do
            expect do
              post provider
              user.reload
            end.to change { user.identities.count }.by(1)
          end

          context 'and is not allowed to link the provider' do
            before do
              allow_any_instance_of(IdentityProviderPolicy).to receive(:can?).with(:link).and_return(false)
            end

            it 'returns 403' do
              post provider

              expect(response).to have_gitlab_http_status(403)
            end
          end
        end

        shared_context 'sign_up' do
          let(:user) { double(email: +'new@example.com') }

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
      mock_auth_hash_with_saml_xml('saml', +'my-uid', user.email, mock_saml_response)
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

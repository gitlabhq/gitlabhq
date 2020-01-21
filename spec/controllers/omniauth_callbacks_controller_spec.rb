# frozen_string_literal: true

require 'spec_helper'

describe OmniauthCallbacksController, type: :controller, do_not_mock_admin_mode: true do
  include LoginHelpers

  describe 'omniauth' do
    let(:user) { create(:omniauth_user, extern_uid: extern_uid, provider: provider) }
    let(:additional_info) { {} }

    before do
      @original_env_config_omniauth_auth = mock_auth_hash(provider.to_s, extern_uid, user.email, additional_info: additional_info )
      stub_omniauth_provider(provider, context: request)
    end

    after do
      Rails.application.env_config['omniauth.auth'] = @original_env_config_omniauth_auth
    end

    context 'a deactivated user' do
      let(:provider) { :github }
      let(:extern_uid) { 'my-uid' }

      before do
        user.deactivate!
        post provider
      end

      it 'allows sign in' do
        expect(request.env['warden']).to be_authenticated
      end

      it 'activates the user' do
        expect(user.reload.active?).to be_truthy
      end

      it 'shows reactivation flash message after logging in' do
        expect(flash[:notice]).to eq('Welcome back! Your account had been deactivated due to inactivity but is now reactivated.')
      end
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
      shared_context 'sign_up' do
        let(:user) { double(email: 'new@example.com') }

        before do
          stub_omniauth_setting(block_auto_created_users: false)
        end
      end

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

      context 'salesforce' do
        let(:extern_uid) { 'my-uid' }
        let(:provider) { :salesforce }
        let(:additional_info) { { extra: { email_verified: false } } }

        context 'without verified email' do
          it 'does not allow sign in' do
            post 'salesforce'

            expect(request.env['warden']).not_to be_authenticated
            expect(response.status).to eq(302)
            expect(controller).to set_flash[:alert].to('Email not verified. Please verify your email in Salesforce.')
          end
        end

        context 'with verified email' do
          include_context 'sign_up'
          let(:additional_info) { { extra: { email_verified: true } } }

          it 'allows sign in' do
            post 'salesforce'

            expect(request.env['warden']).to be_authenticated
          end
        end
      end
    end
  end

  describe '#saml' do
    let(:last_request_id) { 'ONELOGIN_4fee3b046395c4e751011e97f8900b5273d56685' }
    let(:user) { create(:omniauth_user, :two_factor, extern_uid: 'my-uid', provider: 'saml') }
    let(:mock_saml_response) { File.read('spec/fixtures/authentication/saml_response.xml') }
    let(:saml_config) { mock_saml_config_with_upstream_two_factor_authn_contexts }

    def stub_last_request_id(id)
      session['last_authn_request_id'] = id
    end

    before do
      stub_last_request_id(last_request_id)
      stub_omniauth_saml_config({ enabled: true, auto_link_saml_user: true, allow_single_sign_on: ['saml'],
                                  providers: [saml_config] })
      mock_auth_hash_with_saml_xml('saml', +'my-uid', user.email, mock_saml_response)
      request.env['devise.mapping'] = Devise.mappings[:user]
      request.env['omniauth.auth'] = Rails.application.env_config['omniauth.auth']
    end

    context 'sign up' do
      before do
        user.destroy
      end

      it 'denies login if sign up is enabled, but block_auto_created_users is set' do
        post :saml, params: { SAMLResponse: mock_saml_response }

        expect(flash[:alert]).to start_with 'Your account has been blocked.'
      end

      it 'accepts login if sign up is enabled' do
        stub_omniauth_setting(block_auto_created_users: false)

        post :saml, params: { SAMLResponse: mock_saml_response }

        expect(request.env['warden']).to be_authenticated
      end

      it 'denies login if sign up is not enabled' do
        stub_omniauth_setting(allow_single_sign_on: false, block_auto_created_users: false)

        post :saml, params: { SAMLResponse: mock_saml_response }

        expect(flash[:alert]).to start_with 'Signing in using your saml account without a pre-existing GitLab account is not allowed.'
      end
    end

    context 'with GitLab initiated request' do
      before do
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

    context 'with IdP initiated request' do
      let(:user) { create(:user) }
      let(:last_request_id) { '99999' }

      before do
        sign_in user
      end

      it 'lets the user know their account isn\'t linked yet' do
        post :saml, params: { SAMLResponse: mock_saml_response }

        expect(flash[:notice]).to eq 'Request to link SAML account must be authorized'
      end

      it 'redirects to profile account page' do
        post :saml, params: { SAMLResponse: mock_saml_response }

        expect(response).to redirect_to(profile_account_path)
      end

      it 'doesn\'t link a new identity to the user' do
        expect { post :saml, params: { SAMLResponse: mock_saml_response } }.not_to change { user.identities.count }
      end
    end
  end

  describe 'enable admin mode' do
    include_context 'custom session'

    let(:provider) { :auth0 }
    let(:extern_uid) { 'my-uid' }
    let(:user) { create(:omniauth_user, extern_uid: extern_uid, provider: provider) }

    def reauthenticate_and_check_admin_mode(expected_admin_mode:)
      # Initially admin mode disabled
      expect(subject.current_user_mode.admin_mode?).to be(false)

      # Trigger OmniAuth admin mode flow and expect admin mode status
      post provider

      expect(request.env['warden']).to be_authenticated
      expect(subject.current_user_mode.admin_mode?).to be(expected_admin_mode)
    end

    context 'user and admin mode requested by the same user' do
      before do
        sign_in user

        mock_auth_hash(provider.to_s, extern_uid, user.email, additional_info: {})
        stub_omniauth_provider(provider, context: request)
      end

      context 'with a regular user' do
        it 'cannot be enabled' do
          reauthenticate_and_check_admin_mode(expected_admin_mode: false)

          expect(response).to redirect_to(root_path)
        end
      end

      context 'with an admin user' do
        let(:user) { create(:omniauth_user, extern_uid: extern_uid, provider: provider, access_level: :admin) }

        context 'when requested first' do
          before do
            subject.current_user_mode.request_admin_mode!
          end

          it 'can be enabled' do
            reauthenticate_and_check_admin_mode(expected_admin_mode: true)

            expect(response).to redirect_to(admin_root_path)
          end
        end

        context 'when not requested first' do
          it 'cannot be enabled' do
            reauthenticate_and_check_admin_mode(expected_admin_mode: false)

            expect(response).to redirect_to(root_path)
          end
        end
      end
    end

    context 'user and admin mode requested by different users' do
      let(:reauth_extern_uid) { 'another_uid' }
      let(:reauth_user) { create(:omniauth_user, extern_uid: reauth_extern_uid, provider: provider) }

      before do
        sign_in user

        mock_auth_hash(provider.to_s, reauth_extern_uid, reauth_user.email, additional_info: {})
        stub_omniauth_provider(provider, context: request)
      end

      context 'with a regular user' do
        it 'cannot be enabled' do
          reauthenticate_and_check_admin_mode(expected_admin_mode: false)

          expect(response).to redirect_to(profile_account_path)
        end
      end

      context 'with an admin user' do
        let(:user) { create(:omniauth_user, extern_uid: extern_uid, provider: provider, access_level: :admin) }
        let(:reauth_user) { create(:omniauth_user, extern_uid: reauth_extern_uid, provider: provider, access_level: :admin) }

        context 'when requested first' do
          before do
            subject.current_user_mode.request_admin_mode!
          end

          it 'cannot be enabled' do
            reauthenticate_and_check_admin_mode(expected_admin_mode: false)

            expect(response).to redirect_to(new_admin_session_path)
          end
        end

        context 'when not requested first' do
          it 'cannot be enabled' do
            reauthenticate_and_check_admin_mode(expected_admin_mode: false)

            expect(response).to redirect_to(profile_account_path)
          end
        end
      end
    end
  end
end

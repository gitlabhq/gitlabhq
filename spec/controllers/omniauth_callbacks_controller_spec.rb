# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OmniauthCallbacksController, type: :controller, feature_category: :system_access do
  include LoginHelpers

  shared_examples 'store provider2FA value in session' do
    before do
      stub_omniauth_setting(allow_bypass_two_factor: true)
      saml_config.args[:upstream_two_factor_authn_contexts] << "urn:oasis:names:tc:SAML:2.0:ac:classes:Password"
      sign_in user
    end

    it "sets the session variable for provider 2FA" do
      post :saml, params: { SAMLResponse: mock_saml_response }

      expect(session[:provider_2FA]).to eq(true)
    end
  end

  shared_examples 'omniauth sign in that remembers user' do
    before do
      stub_omniauth_setting(allow_bypass_two_factor: allow_bypass_two_factor)
      (request.env['omniauth.params'] ||= {}).deep_merge!('remember_me' => omniauth_params_remember_me)
    end

    if params[:call_remember_me]
      it 'calls devise method remember_me' do
        expect(controller).to receive(:remember_me).with(user).and_call_original

        post_action
      end
    else
      it 'does not calls devise method remember_me' do
        expect(controller).not_to receive(:remember_me)

        post_action
      end
    end
  end

  shared_examples 'omniauth sign in that remembers user with two factor enabled' do
    using RSpec::Parameterized::TableSyntax

    subject(:post_action) { post provider }

    where(:allow_bypass_two_factor, :omniauth_params_remember_me, :call_remember_me) do
      true  | '1' | true
      true  | '0' | false
      true  | nil | false
      false  | '1' | false
      false  | '0' | false
      false  | nil | false
    end

    with_them do
      it_behaves_like 'omniauth sign in that remembers user'
    end
  end

  shared_examples 'omniauth sign in that remembers user with two factor disabled' do
    context "when user selects remember me for omniauth sign in flow" do
      using RSpec::Parameterized::TableSyntax

      subject(:post_action) { post provider }

      where(:allow_bypass_two_factor, :omniauth_params_remember_me, :call_remember_me) do
        true  | '1' | true
        true  | '0' | false
        true  | nil | false
        false  | '1' | true
        false  | '0' | false
        false  | nil | false
      end

      with_them do
        it_behaves_like 'omniauth sign in that remembers user'
      end
    end
  end

  shared_examples 'when user has dismissed broadcast messages' do
    let_it_be(:message_banner) { create(:broadcast_message, broadcast_type: :banner) }
    let_it_be(:message_notification) { create(:broadcast_message, broadcast_type: :notification) }
    let_it_be(:other_message) { create(:broadcast_message, broadcast_type: :banner) }

    before do
      create(:broadcast_message_dismissal, broadcast_message: message_banner, user: user)
      create(:broadcast_message_dismissal, broadcast_message: message_notification, user: user)
      create(:broadcast_message_dismissal, broadcast_message: other_message)

      sign_in user
    end

    it 'creates dismissed cookies based on db records' do
      expect(cookies["hide_broadcast_message_#{message_banner.id}"]).to be_nil
      expect(cookies["hide_broadcast_message_#{message_notification.id}"]).to be_nil
      expect(cookies["hide_broadcast_message_#{other_message.id}"]).to be_nil

      post_action

      expect(cookies["hide_broadcast_message_#{message_banner.id}"]).to be(true)
      expect(cookies["hide_broadcast_message_#{message_notification.id}"]).to be(true)
      expect(cookies["hide_broadcast_message_#{other_message.id}"]).to be_nil
    end
  end

  describe 'omniauth', :with_current_organization do
    let(:user) { create(:omniauth_user, extern_uid: extern_uid, provider: provider) }
    let(:omniauth_email) { user.email }
    let(:additional_info) { {} }

    before do
      @original_env_config_omniauth_auth = mock_auth_hash(provider.to_s, extern_uid, omniauth_email, additional_info: additional_info)
      stub_omniauth_provider(provider, context: request)
    end

    after do
      Rails.application.env_config['omniauth.auth'] = @original_env_config_omniauth_auth
    end

    context 'when authentication succeeds' do
      let(:extern_uid) { 'my-uid' }
      let(:provider) { :github }

      context 'without signed-in user' do
        it 'increments Prometheus counter' do
          expect { post(provider) }.to(
            change do
              Gitlab::Metrics.registry
                             .get(:gitlab_omniauth_login_total)
                             .get(omniauth_provider: 'github', status: 'succeeded')
            end.by(1)
          )
        end
      end

      context 'with signed-in user' do
        before do
          sign_in user
        end

        it_behaves_like 'when user has dismissed broadcast messages' do
          let(:post_action) { post provider }
        end

        it 'increments Prometheus counter' do
          expect { post(provider) }.to(
            change do
              Gitlab::Metrics.registry
                             .get(:gitlab_omniauth_login_total)
                             .get(omniauth_provider: 'github', status: 'succeeded')
            end.by(1)
          )
        end
      end
    end

    context 'for a deactivated user' do
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

    context 'when sign in is not valid' do
      let(:provider) { :github }
      let(:extern_uid) { 'my-uid' }

      it 'renders omniauth error page' do
        allow_next_instance_of(Gitlab::Auth::OAuth::User) do |instance|
          allow(instance).to receive(:valid_sign_in?).and_return(false)
        end

        post provider

        expect(response).to render_template("errors/omniauth_error")
        expect(response).to have_gitlab_http_status(:unprocessable_entity)
      end
    end

    context 'when the user is on the last sign in attempt' do
      let(:extern_uid) { 'my-uid' }

      before do
        user.update!(failed_attempts: User.maximum_attempts.pred)
        subject.set_response!(ActionDispatch::Response.new)
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

      before do
        request.env['omniauth.error'] = OneLogin::RubySaml::ValidationError.new("Fingerprint mismatch")
        request.env['omniauth.error.strategy'] = OmniAuth::Strategies::SAML.new(nil)
        allow(@routes).to receive(:generate_extras).and_return(['/users/auth/saml/callback', []])
      end

      it 'calls through to the failure handler' do
        ForgeryProtection.with_forgery_protection do
          post :failure
        end

        expect(flash[:alert]).to match(/Fingerprint mismatch/)
      end

      it 'increments Prometheus counter' do
        ForgeryProtection.with_forgery_protection do
          expect { post :failure }.to(
            change do
              Gitlab::Metrics.registry
                             .get(:gitlab_omniauth_login_total)
                             .get(omniauth_provider: 'saml', status: 'failed')
            end.by(1)
          )
        end
      end
    end

    context 'when a redirect fragment is provided' do
      let(:provider) { :jwt }
      let(:extern_uid) { 'my-uid' }

      before do
        request.env['omniauth.params'] = { 'redirect_fragment' => 'L101' }
      end

      it_behaves_like 'omniauth sign in that remembers user with two factor disabled'

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

      context 'when a user has 2FA enabled' do
        let(:user) { create(:omniauth_user, :two_factor, extern_uid: extern_uid, provider: provider) }

        it_behaves_like 'omniauth sign in that remembers user with two factor enabled'
      end

      context 'when redirect fragment contains special characters' do
        before do
          request.env['omniauth.params'] = { 'redirect_fragment' => 'confirm-merge_request_diff_id-context' }
        end

        it 'redirects with fragment' do
          post provider, session: { user_return_to: '/fake/url' }

          expect(response).to redirect_to('/fake/url#confirm-merge_request_diff_id-context')
        end
      end

      context 'when stored redirect fragment is malicious' do
        let(:malicious_redirect_fragment) { '#code=test_code&' }

        before do
          request.env['omniauth.params'] = { 'redirect_fragment' => malicious_redirect_fragment }
        end

        it 'fails login and redirects to login path' do
          post provider, session: { user_return_to: '/fake/url#replaceme' }

          expect(response.redirect?).to be true
          expect(response).to redirect_to(new_user_session_path)
          expect(flash[:alert]).to match(/Invalid state/)
        end

        context 'when fragment has encoded content' do
          let_it_be(:malicious_redirect_fragment, reload: true) { '#code%3Dtest_code&L90' }

          it 'fails login and redirects to login path' do
            post provider, session: { user_return_to: '/fake/url#replaceme' }

            expect(response.redirect?).to be true
            expect(response).to redirect_to(new_user_session_path)
            expect(flash[:alert]).to match(/Invalid state/)
          end
        end
      end
    end

    context 'with strategies' do
      shared_context 'with sign_up' do
        let(:user) { double(email: 'new@example.com') }

        before do
          stub_omniauth_setting(block_auto_created_users: false)
        end
      end

      context 'for github' do
        let(:extern_uid) { 'my-uid' }
        let(:provider) { :github }

        it_behaves_like 'known sign in' do
          let(:post_action) { post provider }
        end

        it 'allows sign in' do
          post provider

          expect(request.env['warden']).to be_authenticated
        end

        it 'creates an authentication event record' do
          expect { post provider }.to change { AuthenticationEvent.count }.by(1)
          expect(AuthenticationEvent.last.provider).to eq(provider.to_s)
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

              expect(response).to have_gitlab_http_status(:forbidden)
            end
          end
        end

        it_behaves_like 'omniauth sign in that remembers user with two factor disabled'

        context 'when a user has 2FA enabled' do
          render_views

          let(:user) { create(:omniauth_user, :two_factor, extern_uid: 'my-uid', provider: provider) }

          context 'when a user is unconfirmed' do
            before do
              stub_application_setting_enum('email_confirmation_setting', 'hard')

              user.update!(confirmed_at: nil)
            end

            it 'redirects to login page' do
              post provider

              expect(response).to redirect_to(new_user_session_path)
              expect(flash[:alert]).to match(/You have to confirm your email address before continuing./)
            end
          end

          context 'when a user is confirmed' do
            it 'returns 200 response' do
              expect(response).to have_gitlab_http_status(:ok)
            end
          end

          it_behaves_like 'omniauth sign in that remembers user with two factor enabled'
        end

        context 'for sign up' do
          include_context 'with sign_up'

          it 'is allowed' do
            post provider

            expect(request.env['warden']).to be_authenticated
          end

          it_behaves_like Onboarding::Redirectable do
            let(:email) { user.email }

            subject(:post_create) { post provider }
          end
        end

        context 'when OAuth is disabled' do
          before do
            stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
            settings = Gitlab::CurrentSettings.current_application_settings
            settings.update!(disabled_oauth_sign_in_sources: [provider.to_s])
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
            user.identities.destroy_all # rubocop: disable Cop/DestroyAll
            sign_in(user)

            expect { post provider }.to change { user.reload.identities.count }.by(1)
          end

          context 'for sign up' do
            include_context 'with sign_up'

            it 'is prevented' do
              post provider

              expect(request.env['warden']).not_to be_authenticated
            end
          end
        end
      end

      context 'for auth0' do
        let(:extern_uid) { '' }
        let(:provider) { :auth0 }

        it_behaves_like 'omniauth sign in that remembers user with two factor disabled' do
          let(:extern_uid) { 'my-uid' }
        end

        it 'does not allow sign in without extern_uid' do
          post 'auth0'

          expect(request.env['warden']).not_to be_authenticated
          expect(response).to have_gitlab_http_status(:found)
          expect(controller).to set_flash[:alert].to('Wrong extern UID provided. Make sure Auth0 is configured correctly.')
        end

        context 'when a user has 2FA enabled' do
          let(:user) { create(:omniauth_user, :two_factor, extern_uid: extern_uid, provider: provider) }

          it_behaves_like 'omniauth sign in that remembers user with two factor enabled' do
            let(:extern_uid) { 'my-uid' }
          end
        end
      end

      context 'for atlassian_oauth2' do
        let(:provider) { :atlassian_oauth2 }
        let(:extern_uid) { 'my-uid' }

        context 'when the user and identity already exist' do
          let(:user) { create(:atlassian_user, extern_uid: extern_uid) }

          it_behaves_like 'omniauth sign in that remembers user with two factor disabled'

          it 'allows sign-in' do
            post :atlassian_oauth2

            expect(request.env['warden']).to be_authenticated
          end

          context 'when a user has 2FA enabled' do
            let(:user) { create(:atlassian_user, :two_factor, extern_uid: extern_uid) }

            it_behaves_like 'omniauth sign in that remembers user with two factor enabled'
          end
        end

        context 'for a new user' do
          before do
            @original_url = Settings.gitlab.url
            Settings.gitlab.url = 'https://www.example.com:43/gitlab'
            stub_omniauth_setting(enabled: true, auto_link_user: true, allow_single_sign_on: ['atlassian_oauth2'])

            user.destroy!
          end

          after do
            Settings.gitlab.url = @original_url
          end

          it 'denies sign-in if sign-up is enabled, but block_auto_created_users is set' do
            post :atlassian_oauth2

            expect(flash[:alert]).to start_with 'Your account is pending approval'
          end

          it 'accepts sign-in if sign-up is enabled' do
            stub_omniauth_setting(block_auto_created_users: false)

            post :atlassian_oauth2

            expect(request.env['warden']).to be_authenticated
          end

          it 'denies sign-in if sign-up is not enabled' do
            stub_omniauth_setting(allow_single_sign_on: false, block_auto_created_users: false)

            post :atlassian_oauth2

            expect(flash[:alert]).to eq('Signing in using your Atlassian account without a pre-existing account in example.com:43/gitlab is not allowed. Create an account in example.com:43/gitlab first, and then <a href="/help/user/profile/_index.md#sign-in-services">connect it to your Atlassian account</a>.')
          end
        end
      end

      context 'for salesforce' do
        let(:extern_uid) { 'my-uid' }
        let(:provider) { :salesforce }
        let(:additional_info) { { extra: { email_verified: false } } }

        context 'without verified email' do
          it 'does not allow sign in' do
            post 'salesforce'

            expect(request.env['warden']).not_to be_authenticated
            expect(response).to have_gitlab_http_status(:found)
            expect(controller).to set_flash[:alert].to('Email not verified. Please verify your email in Salesforce.')
          end
        end

        context 'with verified email' do
          include_context 'with sign_up'
          let(:additional_info) { { extra: { email_verified: true } } }

          it_behaves_like 'omniauth sign in that remembers user with two factor disabled' do
            let(:user) { create(:omniauth_user, extern_uid: extern_uid, provider: provider) }
          end

          it 'allows sign in' do
            post 'salesforce'

            expect(request.env['warden']).to be_authenticated
          end

          context 'when a user has 2FA enabled' do
            let(:user) { create(:omniauth_user, :two_factor, extern_uid: extern_uid, provider: provider) }

            it_behaves_like 'omniauth sign in that remembers user with two factor enabled'
          end
        end
      end
    end

    context 'with snowplow tracking', :snowplow do
      let(:provider) { 'google_oauth2' }
      let(:extern_uid) { 'my-uid' }

      context 'when sign_in' do
        it 'does not track the event' do
          post provider
          expect_no_snowplow_event
        end
      end

      context 'when sign_up' do
        let(:user) { double(email: generate(:email)) }

        it 'tracks the event' do
          post provider

          expect_snowplow_event(
            category: described_class.name,
            action: "#{provider}_sso",
            user: User.find_by(email: user.email)
          )
        end
      end
    end

    context "when user's identity with untrusted extern_uid" do
      let(:provider) { 'bitbucket' }
      let(:extern_uid) { 'untrusted-uid' }
      let(:omniauth_email) { 'bitbucketuser@example.com' }

      before do
        user.identities.with_extern_uid(provider, extern_uid).update!(trusted_extern_uid: false)
      end

      it 'shows warning when attempting login' do
        post provider

        expect(response).to redirect_to new_user_session_path
        expect(flash[:alert]).to eq('Signing in using your Bitbucket account has been disabled for security reasons. Please sign in to your GitLab account using another authentication method and reconnect to your Bitbucket account.')
      end
    end
  end

  describe '#openid_connect' do
    let(:user) { create(:omniauth_user, extern_uid: extern_uid, provider: provider) }
    let(:extern_uid) { 'my-uid' }
    let(:provider) { 'openid_connect' }

    before do
      prepare_provider_route('openid_connect')

      mock_auth_hash(provider, extern_uid, user.email, additional_info: {})

      request.env['devise.mapping'] = Devise.mappings[:user]
      request.env['omniauth.auth'] = Rails.application.env_config['omniauth.auth']
    end

    it_behaves_like 'known sign in' do
      let(:post_action) { post provider }
    end

    it_behaves_like 'omniauth sign in that remembers user with two factor disabled'

    it_behaves_like 'when user has dismissed broadcast messages' do
      let(:post_action) { post provider }
    end

    it 'allows sign in' do
      post provider

      expect(request.env['warden']).to be_authenticated
    end

    context 'when a user has 2FA enabled' do
      let(:user) { create(:omniauth_user, :two_factor, extern_uid: extern_uid, provider: provider) }

      it_behaves_like 'omniauth sign in that remembers user with two factor enabled'
    end

    context 'when multiple OIDC providers are configured' do
      let(:oidc_providers) do
        [
          {
            'name' => 'openid_connect',
            'args' => {
              'name' => 'openid_connect',
              'strategy_class' => "OmniAuth::Strategies::OpenIDConnect",
              'client_options' => { 'gitlab' => {} }
            }
          },
          {
            'name' => 'openid_connect2',
            'args' => {
              'name' => 'openid_connect2',
              'strategy_class' => "OmniAuth::Strategies::OpenIDConnect",
              'client_options' => { 'gitlab' => {} }
            }
          }
        ]
      end

      let(:provider_settings) { oidc_providers.map { |provider| GitlabSettings::Options.new(provider) } }
      let(:provider_names) { provider_settings.map(&:name).map(&:to_s) }

      context 'when a non-default provider is used', :aggregate_failures do
        let(:provider2) { provider_names[1] }
        let(:user) { create(:omniauth_user, extern_uid: "my-uid2", provider: provider2.to_sym) }

        controller(described_class) do
          alias_method :openid_connect2, :handle_omniauth
        end

        before do
          prepare_provider_route(provider2)
          allow(routes).to receive(:generate_extras).and_return(["/users/auth/#{provider2}/callback", []])

          stub_omniauth_setting(
            enabled: true,
            block_auto_created_users: false,
            allow_single_sign_on: provider_names,
            providers: provider_settings
          )

          request.env['devise.mapping'] = Devise.mappings[:user]
          request.env['omniauth.auth'] = Rails.application.env_config['omniauth.auth']

          mock_auth_hash(provider2, "my-uid2", user.email)
          stub_omniauth_provider(provider2, context: request)
        end

        it 'authenticates a user with the non-default provider' do
          prov_names = provider_names.map(&:to_sym)

          expect(controller).to receive(provider2.to_sym).and_call_original
          expect(AuthHelper.oidc_providers).to match(prov_names)

          post provider2.to_sym

          expect(request.env['warden']).to be_authenticated
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
      stub_omniauth_saml_config(
        enabled: true,
        auto_link_saml_user: true,
        allow_single_sign_on: ['saml'],
        providers: [saml_config]
      )
      mock_auth_hash_with_saml_xml('saml', +'my-uid', user.email, mock_saml_response)
      request.env['devise.mapping'] = Devise.mappings[:user]
      request.env['omniauth.auth'] = Rails.application.env_config['omniauth.auth']
    end

    it_behaves_like 'known sign in' do
      let(:user) { create(:omniauth_user, extern_uid: 'my-uid', provider: 'saml') }
      let(:post_action) { post :saml, params: { SAMLResponse: mock_saml_response } }
    end

    it_behaves_like 'when user has dismissed broadcast messages' do
      let(:post_action) { post :saml, params: { SAMLResponse: mock_saml_response } }
    end

    context 'for sign up', :with_current_organization do
      before do
        user.destroy!
      end

      it 'denies login if sign up is enabled, but block_auto_created_users is set' do
        post :saml, params: { SAMLResponse: mock_saml_response }
        expect(flash[:alert]).to start_with 'Your account is pending approval'
      end

      it 'accepts login if sign up is enabled' do
        stub_omniauth_setting(block_auto_created_users: false)

        post :saml, params: { SAMLResponse: mock_saml_response }

        expect(request.env['warden']).to be_authenticated
      end

      describe 'when registering a new account is allowed' do
        before do
          allow(Gitlab::CurrentSettings).to receive(:allow_signup?).and_return(true)
        end

        it 'denies login if sign up is not enabled' do
          stub_omniauth_setting(allow_single_sign_on: false, block_auto_created_users: false)

          post :saml, params: { SAMLResponse: mock_saml_response }

          expect(flash[:alert]).to eq("Signing in using your SAML account without a pre-existing account in #{Gitlab.config.gitlab.host} is not allowed. Create an account in #{Gitlab.config.gitlab.host} first, and then <a href=\"/help/user/profile/_index.md#sign-in-services\">connect it to your SAML account</a>.")
          expect(response).to redirect_to(new_user_registration_path)
        end
      end

      describe 'when registering a new account is not allowed' do
        before do
          allow(Gitlab::CurrentSettings).to receive(:allow_signup?).and_return(false)
        end

        it 'denies login if sign up is not enabled' do
          stub_omniauth_setting(allow_single_sign_on: false, block_auto_created_users: false)

          post :saml, params: { SAMLResponse: mock_saml_response }

          expect(flash[:alert]).to eq("Signing in using your SAML account without a pre-existing account in #{Gitlab.config.gitlab.host} is not allowed.")
          expect(response).to redirect_to(new_user_session_path)
        end
      end

      it 'logs saml_response for debugging' do
        expect(Gitlab::AuthLogger).to receive(:info).with(payload_type: 'saml_response', saml_response: anything)

        post :saml, params: { SAMLResponse: mock_saml_response }
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

      context 'with IDP bypass two factor request' do
        let(:user) { create(:omniauth_user, extern_uid: 'my-uid', provider: 'saml') }

        it_behaves_like 'store provider2FA value in session'
      end
    end

    context 'with a blocked user trying to log in when there are hooks set up' do
      let(:user) { create(:omniauth_user, extern_uid: 'my-uid', provider: 'saml') }

      subject(:post_action) { post :saml, params: { SAMLResponse: mock_saml_response } }

      before do
        create(:system_hook)
        user.block!
      end

      it { expect { post_action }.not_to raise_error }
    end

    context 'with a non default SAML provider' do
      let(:user) { create(:omniauth_user, extern_uid: 'my-uid', provider: 'saml') }

      controller(described_class) do
        alias_method :saml_okta, :handle_omniauth
      end

      before do
        allow(AuthHelper).to receive(:saml_providers).and_return([:saml, :saml_okta])
        allow(@routes).to receive(:generate_extras).and_return(['/users/auth/saml_okta/callback', []])
      end

      it 'authenticate with SAML module' do
        expect(@controller).to receive(:omniauth_flow).with(Gitlab::Auth::Saml).and_call_original
        post :saml_okta, params: { SAMLResponse: mock_saml_response }

        expect(request.env['warden']).to be_authenticated
      end
    end

    context 'with IDP bypass two factor request' do
      it_behaves_like 'store provider2FA value in session'
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

    context 'when user and admin mode is requested by the same user' do
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

    context 'when user and admin mode is requested by different users' do
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

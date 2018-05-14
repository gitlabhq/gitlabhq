require 'spec_helper'

describe OmniauthCallbacksController do
  include LoginHelpers

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
          user.identities.destroy_all
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

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::SessionsController, :do_not_mock_admin_mode, feature_category: :system_access do
  include Authn::WebauthnSpecHelpers

  include_context 'custom session'

  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe '#new' do
    context 'for regular users' do
      it 'shows error page' do
        get :new

        expect(response).to have_gitlab_http_status(:not_found)
        expect(controller.current_user_mode.admin_mode?).to be(false)
      end
    end

    context 'for admin users' do
      let(:user) { create(:admin) }

      it 'renders a password form' do
        get :new

        expect(response).to render_template :new
        expect(controller.current_user_mode.admin_mode?).to be(false)
      end

      context 'already in admin mode' do
        before do
          controller.current_user_mode.request_admin_mode!
          controller.current_user_mode.enable_admin_mode!(password: user.password)
        end

        it 'redirects to original location' do
          get :new

          expect(response).to redirect_to(admin_root_path)
          expect(controller.current_user_mode.admin_mode?).to be(true)
        end
      end
    end
  end

  describe '#create' do
    context 'for regular users' do
      it 'shows error page' do
        post :create

        expect(response).to have_gitlab_http_status(:not_found)
        expect(controller.current_user_mode.admin_mode?).to be(false)
      end
    end

    context 'for admin users' do
      shared_examples '2FA sign-in with passkeys' do
        context 'with passkeys' do
          let!(:passkey) { create_passkey(user) }

          let(:device_response) { device_response_after_authentication(user, passkey) }

          let(:session_params) { { otp_user_id: user.id, challenge: challenge } }
          let(:user_params) { { device_response: device_response } }

          def authenticate_2fa_with_passkeys
            controller.store_location_for(:redirect, admin_root_path)
            controller.current_user_mode.request_admin_mode!

            post(:create, params: { user: user_params }, session: session_params)
          end

          it 'allows a passkey to be used for 2FA' do
            allow_next_instance_of(User) do |instance|
              expect(instance).to receive(:get_all_webauthn_credential_ids)
            end

            authenticate_2fa_with_passkeys
          end

          context 'when authenticated with a passkey' do
            it 'authenticates successfully' do
              authenticate_2fa_with_passkeys

              expect(response).to redirect_to(admin_root_path)
              expect(controller.current_user_mode.admin_mode?).to be_truthy
            end
          end

          context 'when failed to authenticate with a passkey' do
            let(:device_response) { 'invalid_response' }

            it 'shows a flash alert from the authenticate service' do
              authenticate_2fa_with_passkeys

              expect(controller.current_user_mode.admin_mode?).to be_falsy
              expect(flash[:alert]).to be_present
            end
          end

          context 'when passkey authentication is disabled for user' do
            before do
              allow_next_found_instance_of(User) do |instance|
                allow(instance).to receive(:allow_passkey_authentication?).and_return(false)
              end
            end

            it 'does not allow passkeys to be used for 2FA' do
              allow_next_instance_of(User) do |instance|
                expect(instance).not_to receive(:get_all_webauthn_credential_ids)
              end

              authenticate_2fa_with_passkeys
            end

            it 'does not call a passkey interval event' do
              expect(controller).not_to receive(:track_passkey_internal_event)

              authenticate_2fa_with_passkeys
            end

            it 'does not authenticate the user' do
              authenticate_2fa_with_passkeys

              expect(controller.current_user_mode.admin_mode?).to be_falsy
            end

            it 'returns generic error message' do
              authenticate_2fa_with_passkeys

              expect(flash[:alert]).to eq(_('Failed to connect to your device. Try again.'))
            end
          end
        end
      end

      let(:user) { create(:admin) }

      it 'sets admin mode with a valid password' do
        expect(controller.current_user_mode.admin_mode?).to be(false)

        controller.store_location_for(:redirect, admin_root_path)

        # triggering the auth form will request admin mode
        get :new

        post :create, params: { user: { password: user.password } }

        expect(response).to redirect_to admin_root_path
        expect(controller.current_user_mode.admin_mode?).to be(true)
      end

      it 'fails with an invalid password' do
        expect(controller.current_user_mode.admin_mode?).to be(false)

        controller.store_location_for(:redirect, admin_root_path)

        # triggering the auth form will request admin mode
        get :new

        post :create, params: { user: { password: '' } }

        expect(response).to render_template :new
        expect(controller.current_user_mode.admin_mode?).to be(false)
      end

      it 'fails if not requested first' do
        expect(controller.current_user_mode.admin_mode?).to be(false)

        controller.store_location_for(:redirect, admin_root_path)

        # do not trigger the auth form

        post :create, params: { user: { password: user.password } }

        expect(response).to redirect_to(new_admin_session_path)
        expect(controller.current_user_mode.admin_mode?).to be(false)
      end

      it 'fails if request period expired' do
        expect(controller.current_user_mode.admin_mode?).to be(false)

        controller.store_location_for(:redirect, admin_root_path)

        # triggering the auth form will request admin mode
        get :new

        travel_to(Gitlab::Auth::CurrentUserMode::ADMIN_MODE_REQUESTED_GRACE_PERIOD.from_now) do
          post :create, params: { user: { password: user.password } }

          expect(response).to redirect_to(new_admin_session_path)
          expect(controller.current_user_mode.admin_mode?).to be(false)
        end
      end

      context 'when using two-factor authentication via OTP' do
        let(:user) { create(:admin, :two_factor) }

        def authenticate_2fa(user_params)
          post(:create, params: { user: user_params }, session: { otp_user_id: user.id })
        end

        it 'requests two factor after a valid password is provided' do
          expect(controller.current_user_mode.admin_mode?).to be(false)

          # triggering the auth form will request admin mode
          get :new

          post :create, params: { user: { password: user.password } }

          expect(response).to render_template('admin/sessions/two_factor')
          expect(controller.current_user_mode.admin_mode?).to be(false)
        end

        it 'can login with valid otp' do
          expect(controller.current_user_mode.admin_mode?).to be(false)

          controller.store_location_for(:redirect, admin_root_path)
          controller.current_user_mode.request_admin_mode!

          authenticate_2fa(otp_attempt: user.current_otp)

          expect(response).to redirect_to admin_root_path
          expect(controller.current_user_mode.admin_mode?).to be(true)
        end

        it 'cannot login with invalid otp' do
          expect(controller.current_user_mode.admin_mode?).to be(false)

          controller.current_user_mode.request_admin_mode!

          authenticate_2fa(otp_attempt: 'invalid')

          expect(response).to render_template('admin/sessions/two_factor')
          expect(controller.current_user_mode.admin_mode?).to be(false)
        end

        context 'with password authentication disabled' do
          before do
            stub_application_setting(password_authentication_enabled_for_web: false)
          end

          it 'allows 2FA stage of non-password login' do
            expect(controller.current_user_mode.admin_mode?).to be(false)

            controller.store_location_for(:redirect, admin_root_path)
            controller.current_user_mode.request_admin_mode!

            authenticate_2fa(otp_attempt: user.current_otp)

            expect(response).to redirect_to admin_root_path
            expect(controller.current_user_mode.admin_mode?).to be(true)
          end
        end

        context 'on a read-only instance' do
          before do
            allow(Gitlab::Database).to receive(:read_only?).and_return(true)
          end

          it 'does not attempt to write to the database with valid otp' do
            expect_any_instance_of(User).not_to receive(:save)
            expect_any_instance_of(User).not_to receive(:save!)

            controller.store_location_for(:redirect, admin_root_path)
            controller.current_user_mode.request_admin_mode!

            authenticate_2fa(otp_attempt: user.current_otp)

            expect(response).to redirect_to admin_root_path
          end

          it 'does not attempt to write to the database with invalid otp' do
            expect_any_instance_of(User).not_to receive(:save)
            expect_any_instance_of(User).not_to receive(:save!)

            controller.current_user_mode.request_admin_mode!

            authenticate_2fa(otp_attempt: 'invalid')

            expect(response).to render_template('admin/sessions/two_factor')
            expect(controller.current_user_mode.admin_mode?).to be(false)
          end

          it 'does not attempt to write to the database with backup code' do
            expect_any_instance_of(User).not_to receive(:save)
            expect_any_instance_of(User).not_to receive(:save!)

            controller.current_user_mode.request_admin_mode!

            authenticate_2fa(otp_attempt: user.otp_backup_codes.first)

            expect(response).to render_template('admin/sessions/two_factor')
            expect(controller.current_user_mode.admin_mode?).to be(false)
          end
        end

        it_behaves_like '2FA sign-in with passkeys'
      end

      context 'when using two-factor authentication via WebAuthn' do
        let(:user) { create(:admin, :two_factor_via_webauthn) }

        def authenticate_2fa(user_params)
          post(:create, params: { user: user_params }, session: { otp_user_id: user.id })
        end

        it 'requests two factor after a valid password is provided' do
          expect(controller.current_user_mode.admin_mode?).to be(false)

          # triggering the auth form will request admin mode
          get :new
          post :create, params: { user: { password: user.password } }

          expect(response).to render_template('admin/sessions/two_factor')
          expect(controller.current_user_mode.admin_mode?).to be(false)
        end

        it 'can login with valid auth' do
          allow_next_instance_of(Webauthn::AuthenticateService) do |instance|
            allow(instance).to receive(:execute).and_return(
              ServiceResponse.success
            )
          end

          expect(controller.current_user_mode.admin_mode?).to be(false)

          controller.store_location_for(:redirect, admin_root_path)
          controller.current_user_mode.request_admin_mode!

          authenticate_2fa(login: user.username, device_response: '{}')

          expect(response).to redirect_to admin_root_path
          expect(controller.current_user_mode.admin_mode?).to be(true)
        end

        it 'cannot login with invalid auth' do
          allow_next_instance_of(Webauthn::AuthenticateService) do |instance|
            allow(instance).to receive(:execute).and_return(
              ServiceResponse.error(message: _('Authentication via WebAuthn device failed.'))
            )
          end

          expect(controller.current_user_mode.admin_mode?).to be(false)

          controller.current_user_mode.request_admin_mode!
          authenticate_2fa(login: user.username, device_response: '{}')

          expect(response).to render_template('admin/sessions/two_factor')
          expect(controller.current_user_mode.admin_mode?).to be(false)
        end

        it_behaves_like '2FA sign-in with passkeys'
      end
    end
  end

  describe '#destroy' do
    context 'for regular users' do
      it 'shows error page' do
        post :destroy

        expect(response).to have_gitlab_http_status(:not_found)
        expect(controller.current_user_mode.admin_mode?).to be(false)
      end
    end

    context 'for admin users' do
      let(:user) { create(:admin) }

      it 'disables admin mode and redirects to main page' do
        expect(controller.current_user_mode.admin_mode?).to be(false)

        get :new
        post :create, params: { user: { password: user.password } }
        expect(controller.current_user_mode.admin_mode?).to be(true)

        post :destroy

        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to(root_path)
        expect(controller.current_user_mode.admin_mode?).to be(false)
      end

      context 'for step-up authenticated admin users' do
        let(:session_with_step_up_auth_data) do
          {
            'omniauth_step_up_auth' => {
              'openid_connect' => {
                'admin_mode' => { 'state' => 'succeeded' },
                'other_scope' => { 'state' => 'succeeded' }
              },
              'other_provider' => {
                'admin_mode' => { 'state' => 'failed' }
              }
            }
          }
        end

        subject(:response) { delete :destroy, session: session_with_step_up_auth_data }

        before do
          get :new

          post :create, params: { user: { password: user.password } }
        end

        it 'calls disable_step_up_authentication! for OIDC step-up' do
          expect(::Gitlab::Auth::Oidc::StepUpAuthentication)
            .to receive(:disable_step_up_authentication!).and_call_original

          response

          expect(request.session.dig('omniauth_step_up_auth', 'openid_connect')).not_to have_key('admin_mode')
        end

        it { is_expected.to redirect_to(root_path) }

        context 'when feature flag :omniauth_step_up_auth_for_admin_mode is disabled' do
          before do
            stub_feature_flags(omniauth_step_up_auth_for_admin_mode: false)
          end

          it 'does not call disable_step_up_authentication!' do
            expect(::Gitlab::Auth::Oidc::StepUpAuthentication)
              .not_to receive(:disable_step_up_authentication!).and_call_original

            response

            expect(request.session.dig('omniauth_step_up_auth', 'openid_connect')).to have_key('admin_mode')
          end
        end
      end
    end
  end
end

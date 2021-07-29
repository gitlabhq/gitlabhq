# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::SessionsController, :do_not_mock_admin_mode do
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
            allow(Gitlab::Database.main).to receive(:read_only?).and_return(true)
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
      end

      shared_examples 'when using two-factor authentication via hardware device' do
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
          # we can stub both without an differentiation between webauthn / u2f
          # as these not interfere with each other und this saves us passing aroud
          # parameters
          allow(U2fRegistration).to receive(:authenticate).and_return(true)
          allow_any_instance_of(Webauthn::AuthenticateService).to receive(:execute).and_return(true)

          expect(controller.current_user_mode.admin_mode?).to be(false)

          controller.store_location_for(:redirect, admin_root_path)
          controller.current_user_mode.request_admin_mode!

          authenticate_2fa(login: user.username, device_response: '{}')

          expect(response).to redirect_to admin_root_path
          expect(controller.current_user_mode.admin_mode?).to be(true)
        end

        it 'cannot login with invalid auth' do
          allow(U2fRegistration).to receive(:authenticate).and_return(false)
          allow_any_instance_of(Webauthn::AuthenticateService).to receive(:execute).and_return(false)

          expect(controller.current_user_mode.admin_mode?).to be(false)

          controller.current_user_mode.request_admin_mode!
          authenticate_2fa(login: user.username, device_response: '{}')

          expect(response).to render_template('admin/sessions/two_factor')
          expect(controller.current_user_mode.admin_mode?).to be(false)
        end
      end

      context 'when using two-factor authentication via U2F' do
        it_behaves_like 'when using two-factor authentication via hardware device' do
          let(:user) { create(:admin, :two_factor_via_u2f) }

          before do
            stub_feature_flags(webauthn: false)
          end
        end
      end

      context 'when using two-factor authentication via WebAuthn' do
        it_behaves_like 'when using two-factor authentication via hardware device' do
          let(:user) { create(:admin, :two_factor_via_webauthn) }
        end
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
    end
  end
end

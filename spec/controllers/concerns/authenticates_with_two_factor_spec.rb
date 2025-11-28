# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuthenticatesWithTwoFactor, :aggregate_failures, feature_category: :system_access do
  controller(ActionController::Base) do
    include AuthenticatesWithTwoFactor
    include Devise::Controllers::Rememberable

    def new_passkey
      handle_passwordless_flow
    end

    private

    def passwordless_passkey_params
      permitted_list = [:device_response, :remember_me]
      params.permit(permitted_list)
    end

    def user_params
      params.require(:user).permit(:login, :password, :remember_me, :otp_attempt, :device_response)
    end
  end

  let_it_be_with_reload(:user) { create(:user) }
  let_it_be_with_reload(:passkey) { create(:webauthn_registration, :passkey, user: user) }

  before do
    routes.draw do
      post "new_passkey" => "anonymous#new_passkey"
    end

    allow(controller).to receive(:add_gon_variables)
  end

  subject(:perform_request) do
    post :new_passkey, params: params
  end

  shared_examples 'prompts the user to authenticate with a passkey' do
    it 'calls .prompt_for_passwordless_authentication_via_passkey' do
      expect(controller).to receive(:prompt_for_passwordless_authentication_via_passkey)

      perform_request
    end
  end

  describe '#handle_passwordless_flow' do
    before do
      allow(controller).to receive(:render).with('devise/sessions/passkeys')
    end

    context 'when a device_response is present' do
      let(:params) { { device_response: 'test_response' } }

      context 'when a passkey is found' do
        before do
          allow_next_instance_of(Authn::Passkey::AuthenticateService) do |instance|
            allow(instance).to receive(:execute).and_return(
              ServiceResponse.success(message: _('Passkey successfully authenticated.'), payload: user)
            )
          end
        end

        it 'authenticates successfully' do
          perform_request

          expect(response).to redirect_to(root_path)
        end

        it 'resets 2FA attempts' do
          perform_request

          expect(session[:otp_user_id]).to be_nil
          expect(session[:user_password_hash]).to be_nil
          expect(session[:challenge]).to be_nil
        end

        context 'with remember_me' do
          context 'if remember_me is checked' do
            let(:params) { { device_response: 'test_response', remember_me: '1' } }

            it 'sets a remember_user_token cookie' do
              perform_request

              expect(response.cookies['remember_user_token']).to be_present
            end
          end

          context 'if remember_me is not checked' do
            let(:params) { { device_response: 'test_response', remember_me: '0' } }

            it 'does not set a remember_user_token cookie' do
              perform_request

              expect(response.cookies['remember_user_token']).to be_nil
            end
          end
        end
      end

      context 'when a passkey is not found' do
        let(:params) { { device_response: 'invalid_response' } }

        before do
          allow_next_instance_of(Authn::Passkey::AuthenticateService) do |instance|
            allow(instance).to receive(:execute).and_return(
              ServiceResponse.error(message: _('Passkey failed to authenticate.'))
            )
          end
        end

        it 'renders a flash alert from the backend service' do
          perform_request

          expect(flash[:alert]).to eq('Passkey failed to authenticate.')
        end

        it 'logs an error' do
          expect(Gitlab::AppLogger).to receive(:info)

          perform_request
        end

        it_behaves_like 'prompts the user to authenticate with a passkey'
      end
    end

    context 'when a device_response is not present' do
      let(:params) { {} }

      it_behaves_like 'prompts the user to authenticate with a passkey'
    end
  end

  describe '#destroy_all_but_current_user_session!' do
    def all_sessions_count
      ActiveSession.list(user).size
    end

    it 'invalidates all but the current user session' do
      4.times do
        rack_session = Rack::Session::SessionId.new(SecureRandom.hex(16))
        session = instance_double(ActionDispatch::TestRequest::Session, id: rack_session, '[]': {}, dig: {})
        request = instance_double(
          ActionDispatch::TestRequest,
          { user_agent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 8_1_3 like Mac OS X) AppleWebKit/600.1.4',
            remote_ip: '124.00.22',
            session: session }
        )
        ActiveSession.set(user, request)
      end

      expect(all_sessions_count).to be(4)

      # Sign-in with a new active session
      sign_in(user)
      ActiveSession.set(user, request)

      controller.send(:destroy_all_but_current_user_session!, user, session)

      expect(all_sessions_count).to be(1)
    end
  end

  describe 'private methods' do
    describe '.authenticate_with_two_factor_via_webauthn' do
      before do
        allow(controller).to receive(:params).and_return(
          ActionController::Parameters.new(
            user: {
              device_response: 'test_response'
            }
          )
        )
        allow(controller).to receive(:render).with('devise/sessions/two_factor')
      end

      let(:user) { create(:user, :two_factor_via_webauthn) }

      let(:authenticate_with_two_factor_via_webauthn) do
        controller.send(:authenticate_with_two_factor_via_webauthn, user)
      end

      context 'with a successful Webauthn::AuthenticateService' do
        before do
          allow_next_instance_of(Webauthn::AuthenticateService) do |instance|
            allow(instance).to receive(:execute).and_return(
              ServiceResponse.success
            )
          end
        end

        it 'signs in the user' do
          expect(controller).to receive(:sign_in)

          authenticate_with_two_factor_via_webauthn
        end
      end

      context 'with a failed Webauthn::AuthenticateService' do
        before do
          allow_next_instance_of(Webauthn::AuthenticateService) do |instance|
            allow(instance).to receive(:execute).and_return(
              ServiceResponse.error(message: _('Authentication via WebAuthn device failed.'))
            )
          end
        end

        it 'fails to authenticate' do
          expect(controller).to receive(:handle_two_factor_failure)

          authenticate_with_two_factor_via_webauthn
        end

        it 'renders a flash alert from the backend service' do
          authenticate_with_two_factor_via_webauthn

          expect(flash[:alert]).to eq('Authentication via WebAuthn device failed.')
        end

        it 'logs an error' do
          expect(Gitlab::AppLogger).to receive(:info)

          authenticate_with_two_factor_via_webauthn
        end

        it 'prompts the user for 2FA re-authentication' do
          expect(controller).to receive(:prompt_for_two_factor)

          authenticate_with_two_factor_via_webauthn
        end
      end
    end
  end
end

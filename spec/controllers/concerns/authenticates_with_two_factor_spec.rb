# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuthenticatesWithTwoFactor, :aggregate_failures, feature_category: :system_access do
  controller(ActionController::Base) do
    include AuthenticatesWithTwoFactor
    include Devise::Controllers::Rememberable

    def new_passkey
      handle_passwordless_flow
    end

    def passwordless_passkey_params
      permitted_list = [:device_response, :remember_me]
      params.permit(permitted_list)
    end
  end

  let(:user) { create(:user) }
  let(:passkey) { create(:webauthn_registration, :passkey, user: user) }

  before do
    routes.draw do
      post "new_passkey" => "anonymous#new_passkey"
    end

    allow(controller).to receive(:add_gon_variables)
    allow(controller).to receive(:render).with('devise/sessions/passkeys')
  end

  subject(:perform_request) do
    post :new_passkey, params: params
  end

  describe '#handle_passwordless_flow' do
    shared_examples 'prompts the user to authenticate with a passkey' do
      it 'calls .prompt_for_passwordless_authentication_via_passkey' do
        expect(controller).to receive(:prompt_for_passwordless_authentication_via_passkey)

        perform_request
      end
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
end

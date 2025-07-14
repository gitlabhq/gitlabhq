# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Profiles::ChatNamesController, feature_category: :integrations do
  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe 'POST #create' do
    let(:token) { 'valid_token' }
    let(:chat_name_token_double) { instance_double(Gitlab::ChatNameToken) }
    let(:chat_name_params) do
      {
        team_id: 'T123',
        chat_id: 'U123',
        chat_name: 'test_user'
      }
    end

    before do
      allow(Gitlab::ChatNameToken).to receive(:new).with(token).and_return(chat_name_token_double)
      allow(chat_name_token_double).to receive(:get).and_return(chat_name_params)
      allow(chat_name_token_double).to receive(:delete)
    end

    context 'when save succeeds' do
      it 'sets success flash message and redirects' do
        post :create, params: { token: token }

        expect(flash[:notice]).to include('Authorized test_user')
        expect(response).to redirect_to(user_settings_integration_accounts_path)
      end
    end

    context 'when save fails' do
      it 'sets error flash message and redirects' do
        allow_next_instance_of(ChatName) do |instance|
          allow(instance).to receive(:save).and_return(false)
        end

        post :create, params: { token: token }

        expect(flash[:alert]).to eq('Could not authorize integration account nickname. Try again!')
        expect(response).to redirect_to(user_settings_integration_accounts_path)
      end
    end
  end

  describe 'DELETE #destroy' do
    let_it_be(:chat_name) { create(:chat_name, user: user) }

    it 'destroys the chat_name' do
      expect { delete :destroy, params: { id: chat_name.id } }
        .to change { ChatName.count }.by(-1)
    end

    it 'redirects to the integration accounts page' do
      delete :destroy, params: { id: chat_name.id }

      expect(response).to redirect_to(user_settings_integration_accounts_path)
    end

    context 'when destroy fails' do
      it 'sets error flash message and redirects' do
        mock_chat_name = instance_double(ChatName)
        allow(mock_chat_name).to receive_messages(
          destroy: false,
          chat_name: chat_name.chat_name
        )

        # As chat_names_controller finds the real db object, #destroy would rarely fail naturally
        # Hence, we're intercepting the controller-find process to return failing mock
        allow(controller).to receive(:chat_names).and_return(user.chat_names)
        allow(user.chat_names).to receive(:find).with(chat_name.id.to_s).and_return(mock_chat_name)

        delete :destroy, params: { id: chat_name.id }

        expect(flash[:alert]).to eq("Could not delete account nickname #{chat_name.chat_name}.")
        expect(response).to redirect_to(user_settings_integration_accounts_path)
      end
    end
  end
end

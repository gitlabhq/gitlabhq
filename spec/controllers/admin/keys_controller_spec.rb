# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::KeysController, feature_category: :user_management do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:user) { create(:user) }
  let_it_be(:key) { create(:key, user: user) }

  before do
    sign_in(admin)
  end

  describe 'GET #show' do
    it 'finds the key using permitted params' do
      get :show, params: { user_id: user.username, id: key.id }

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'responds with JS format' do
      get :show, params: { user_id: user.username, id: key.id }, format: :js, xhr: true

      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  describe 'DELETE #destroy' do
    it 'removes the key using permitted params' do
      expect do
        delete :destroy, params: { user_id: user.username, id: key.id }
      end.to change { user.keys.count }.by(-1)

      expect(response).to redirect_to(keys_admin_user_path(user))
      expect(flash[:notice]).to eq('User key was successfully removed.')
    end

    context 'when key destruction fails' do
      before do
        allow_next_found_instance_of(Key) do |key_instance|
          allow(key_instance).to receive(:destroy).and_return(false)
        end
      end

      it 'shows an alert message' do
        delete :destroy, params: { user_id: user.username, id: key.id }

        expect(response).to redirect_to(keys_admin_user_path(user))
        expect(flash[:alert]).to eq('Failed to remove user key.')
      end
    end
  end

  describe '#key_params' do
    it 'permits user_id and id parameters' do
      controller_instance = described_class.new
      allow(controller_instance).to receive(:params).and_return(
        ActionController::Parameters.new(
          user_id: user.username,
          id: key.id,
          extra_param: 'value'
        )
      )

      result = controller_instance.send(:key_params)

      expect(result.keys).to contain_exactly('user_id', 'id')
      expect(result.permitted?).to be true
    end
  end
end

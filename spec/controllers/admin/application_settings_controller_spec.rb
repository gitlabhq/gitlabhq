require 'spec_helper'

describe Admin::ApplicationSettingsController do
  let(:group) { create(:group) }
  let(:project) { create(:project, namespace: group) }
  let(:admin) { create(:admin) }
  let(:user) { create(:user)}

  describe 'GET #usage_data with no access' do
    before do
      sign_in(user)
    end

    it 'returns 404' do
      get :usage_data, format: :html

      expect(response.status).to eq(404)
    end
  end

  describe 'GET #usage_data' do
    before do
      sign_in(admin)
    end

    it 'returns HTML data' do
      get :usage_data, format: :html

      expect(response.body).to start_with('<span')
      expect(response.status).to eq(200)
    end

    it 'returns JSON data' do
      get :usage_data, format: :json

      body = JSON.parse(response.body)
      expect(body["version"]).to eq(Gitlab::VERSION)
      expect(body).to include('counts')
      expect(response.status).to eq(200)
    end
  end
end

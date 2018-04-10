require 'spec_helper'

describe Admin::ApplicationSettingsController do
  include StubENV

  let(:group) { create(:group) }
  let(:project) { create(:project, namespace: group) }
  let(:admin) { create(:admin) }
  let(:user) { create(:user)}

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
  end

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

  describe 'PUT #update' do
    before do
      sign_in(admin)
    end

    it 'updates the password_authentication_enabled_for_git setting' do
      put :update, application_setting: { password_authentication_enabled_for_git: "0" }

      expect(response).to redirect_to(admin_application_settings_path)
      expect(ApplicationSetting.current.password_authentication_enabled_for_git).to eq(false)
    end

    it 'updates the default_project_visibility for string value' do
      put :update, application_setting: { default_project_visibility: "20" }

      expect(response).to redirect_to(admin_application_settings_path)
      expect(ApplicationSetting.current.default_project_visibility).to eq(Gitlab::VisibilityLevel::PUBLIC)
    end

    it 'update the restricted levels for string values' do
      put :update, application_setting: { restricted_visibility_levels: %w[10 20] }

      expect(response).to redirect_to(admin_application_settings_path)
      expect(ApplicationSetting.current.restricted_visibility_levels).to eq([10, 20])
    end

    it 'falls back to defaults when settings are omitted' do
      put :update, application_setting: {}

      expect(response).to redirect_to(admin_application_settings_path)
      expect(ApplicationSetting.current.default_project_visibility).to eq(Gitlab::VisibilityLevel::PRIVATE)
      expect(ApplicationSetting.current.restricted_visibility_levels).to be_empty
    end
  end
end

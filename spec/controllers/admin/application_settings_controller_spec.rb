require 'spec_helper'

describe Admin::ApplicationSettingsController do
  include StubENV

<<<<<<< HEAD
  let(:group) { create(:group) }
  let(:project) { create(:project, namespace: group) }
  let(:admin) { create(:admin) }
  let(:user) { create(:user)}

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
  end

  describe 'PUT #update' do
    before do
      sign_in(admin)
    end

    context 'with valid params' do
      subject { put :update, application_setting: { repository_size_limit: '100' } }

      it 'redirect to application settings page' do
        is_expected.to redirect_to(admin_application_settings_path)
      end

      it 'set flash notice' do
        is_expected.to set_flash[:notice].to('Application settings saved successfully')
      end
    end

    context 'with invalid params' do
      subject! { put :update, application_setting: { repository_size_limit: '-100' } }

      it 'render show template' do
        is_expected.to render_template(:show)
      end

      it 'assigned @application_settings has errors' do
        expect(assigns(:application_setting).errors[:repository_size_limit]).to be_present
      end
    end
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
=======
  let(:admin) { create(:admin) }

  before do
    sign_in(admin)
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
  end

  describe 'PATCH #update' do
    it 'updates the default_project_visibility for string value' do
      patch :update, application_setting: { default_project_visibility: "20" }

      expect(response).to redirect_to(admin_application_settings_path)
      expect(ApplicationSetting.current.default_project_visibility).to eq Gitlab::VisibilityLevel::PUBLIC
    end

    it 'falls back to default with default_project_visibility setting is omitted' do
      patch :update, application_setting: {}

      expect(response).to redirect_to(admin_application_settings_path)
      expect(ApplicationSetting.current.default_project_visibility).to eq Gitlab::VisibilityLevel::PRIVATE
>>>>>>> b22d4c2e9f171b6cabeb537f3a3a0a688a4e0cc3
    end
  end
end

require 'spec_helper'

describe Admin::ApplicationSettingsController do
  include StubENV

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
    end
  end
end

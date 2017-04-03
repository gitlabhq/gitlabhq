require 'spec_helper'

describe Admin::ApplicationSettingsController do
  include StubENV

  let(:admin) { create(:admin) }

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
  end

  describe 'PUT #update' do
    before do
      sign_in(admin)
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

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin updates repository settings', :request_store, :enable_admin_mode,
  feature_category: :source_code_management do
  include StubENV
  include Features::SettingsHelpers

  let_it_be(:admin) { create(:admin) }

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
    sign_in(admin)
    visit repository_admin_application_settings_path
  end

  it 'change Repository storage settings' do
    within_testid('repository-storage-settings') do
      fill_in 'application_setting_repository_storages_weighted_default', with: 50
    end

    expect_save_settings('repository-storage-settings')

    expect(current_settings.repository_storages_weighted).to eq('default' => 50)
  end

  context 'when settings are outdated' do
    before do
      current_settings.update_attribute :repository_storages_weighted, { 'default' => 100, 'outdated' => 100 }
      visit repository_admin_application_settings_path
    end

    it 'still saves' do
      within_testid('repository-storage-settings') do
        fill_in 'application_setting_repository_storages_weighted_default', with: 50
      end

      expect_save_settings('repository-storage-settings')

      expect(current_settings.repository_storages_weighted).to eq('default' => 50)
    end
  end

  context 'for External storage for repository static objects' do
    before do
      encrypted_token = Gitlab::CryptoHelper.aes256_gcm_encrypt('OldToken')
      current_settings.update_attribute :static_objects_external_storage_auth_token_encrypted, encrypted_token
      visit repository_admin_application_settings_path
    end

    it 'changes Repository external storage settings' do
      within_testid('repository-static-objects-settings') do
        fill_in 'application_setting_static_objects_external_storage_url', with: 'http://example.com'
        fill_in 'application_setting_static_objects_external_storage_auth_token', with: 'Token'
      end

      expect_save_settings('repository-static-objects-settings')

      expect(current_settings.static_objects_external_storage_url).to eq('http://example.com')
      expect(current_settings.static_objects_external_storage_auth_token).to eq('Token')
    end
  end

  def current_settings
    ApplicationSetting.current_without_cache
  end
end

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
      fill_field_with_new_value('default', '50')

      expect_save_settings

      expect_field_value('default', '50')
    end
  end

  context 'when settings are outdated' do
    before do
      current_settings.update_attribute :repository_storages_weighted, { 'default' => 100, 'outdated' => 100 }
      visit repository_admin_application_settings_path
    end

    it 'still saves' do
      within_testid('repository-storage-settings') do
        fill_field_with_new_value('default', '50')

        expect_save_settings

        expect_field_value('default', '50')
      end
    end
  end

  context 'for External storage for repository static objects' do
    before do
      encrypted_token = Gitlab::CryptoHelper.aes256_gcm_encrypt('OldToken')
      current_settings.update_attribute :static_objects_external_storage_auth_token_encrypted, encrypted_token
      visit repository_admin_application_settings_path
    end

    it 'changes Repository external storage settings', :aggregate_failures do
      within_testid('repository-static-objects-settings') do
        fill_field_with_new_value(_('External storage URL'), 'http://example.com')
        fill_field_with_new_value(_('External storage authentication token'), 'Token')

        expect_save_settings

        expect_field_value(_('External storage URL'), 'http://example.com')
        expect_field_value(_('External storage authentication token'), 'Token')
      end
    end
  end
end

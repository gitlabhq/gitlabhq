# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Settings Sync in Web IDE', product_group: :remote_development, feature_category: :web_ide, quarantine: {
      issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/516980',
      type: :investigating
    } do
      include_context 'Web IDE test prep'
      let(:project) { create(:project, :with_readme, name: 'webide-settings-sync-project') }
      let(:settings_sync_data) do
        [
          { setting_type: "settings", content: { settings: '{ "test": true }' } },
          { setting_type: "extensions", content: [{ identifier: "test-extension", version: "1.0.0" }] },
          { setting_type: "globalState", content: [{ storage: { "test-storage": true } }] }
        ]
      end

      before do
        load_web_ide(with_extensions_marketplace: true)
        settings_context_hash = get_settings_context_hash

        settings_sync_data.each do |data|
          populate_settings_sync(setting_type: data[:setting_type], content: data[:content],
            settings_context_hash: settings_context_hash)
        end
        populate_settings_sync(
          setting_type: "extensions",
          content: [{ identifier: "bad-test-extension", version: "1.0.0" }],
          settings_context_hash: '1234'
        )
      end

      it 'is enabled by default', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/508735' do
        Page::Project::WebIDE::SettingsSync.perform do |settings_sync|
          expect(settings_sync.enabled?).to be(true)
        end
      end

      it 'loads remote synced data', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/508736' do
        Page::Project::WebIDE::SettingsSync.perform do |settings_sync|
          settings_sync_data.each do |data|
            setting_type = data[:setting_type]
            settings_sync.open_remote_synced_data(setting_type)
            expect(settings_sync.has_opened_synced_data_item?(setting_type)).to be(true)
          end
        end
      end

      it 'loads correct extensions settings based on settings context hash',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/508737' do
        Page::Project::WebIDE::SettingsSync.perform do |settings_sync|
          settings_sync.open_remote_synced_data('extensions')
          expect(settings_sync.has_opened_synced_data_item?('extensions')).to be(true)
          Page::Project::WebIDE::VSCode.perform do |ide|
            ide.within_vscode_editor do
              expect(has_text?('"identifier": "test-extension"')).to be(true)
              expect(has_text?('"identifier": "bad-test-extension"')).to be(false)
            end
          end
        end
      end
    end

    private

    def get_settings_context_hash
      Page::Project::WebIDE::VSCode.perform do |ide|
        ide.within_vscode_editor do
          config_element = find('meta#gl-config-json', visible: false)
          config = JSON.parse(config_element[:'data-settings'])
          config['settingsContextHash']
        end
      end
    end

    def populate_settings_sync(setting_type:, content:, settings_context_hash: nil)
      settings_data = {
        version: 2,
        machineId: "ad91474f-10ea-4479-8076-8367e5e4bf68",
        content: content.to_json
      }

      client = Runtime::User::Store.default_api_client
      url = Runtime::API::Request.new(client,
        "vscode/settings_sync/#{settings_context_hash}/v1/resource/#{setting_type}").url
      Support::API.post(url, settings_data)
    end
  end
end

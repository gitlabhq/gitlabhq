# frozen_string_literal: true

module QA
  include Support::API

  RSpec.shared_context 'Web IDE test prep' do
    let(:user) { Runtime::User::Store.test_user }

    before do
      Flow::Login.sign_in(as: user)
      project.visit!
    end

    after(:context) do
      clear_settings_sync_data
    end

    def load_web_ide(file_name: 'README.md', with_extensions_marketplace: false)
      enable_extensions_marketplace if with_extensions_marketplace

      Page::Project::Show.perform(&:open_web_ide!)
      Page::Project::WebIDE::VSCode.perform do |ide|
        ide.wait_for_ide_to_load(file_name)
      end
    end

    private

    def enable_extensions_marketplace
      Page::Main::Menu.perform(&:click_user_preferences_link)
      Page::Profile::Preferences::Show.perform do |preferences|
        preferences.enable_extensions_marketplace
        preferences.save_preferences
      end

      project.visit!
    end

    def clear_settings_sync_data
      # why: since the same user is used to run QA tests, the Web IDE settings can grow significantly.
      # For example: The Web IDE keeps track of recently opened files with no upper limit set.
      # https://gitlab.com/gitlab-org/gitlab-web-ide/-/issues/399
      client = Runtime::User::Store.default_api_client
      Support::API.delete(Runtime::API::Request.new(client, "vscode/settings_sync/v1/collection").url)
    end
  end
end

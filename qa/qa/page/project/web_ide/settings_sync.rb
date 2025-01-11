# frozen_string_literal: true

module QA
  module Page
    module Project
      module WebIDE
        class SettingsSync < Page::Base
          attr_reader :setting_type_to_ui_metadata_map

          # Unable to use `data-testids` in Settings sync feature as it
          # falls under the VSCode WebIDE, which is built off an iFrame application.
          skip_selectors_check!

          def initialize
            @setting_type_to_ui_metadata_map = {
              settings: {
                label: 'Settings',
                file_name: 'settings.json'
              },
              extensions: {
                label: 'Extensions',
                file_name: 'extensions.json'
              },
              globalState: {
                label: 'UI State',
                file_name: 'globalState.json'
              }
            }.freeze
            super
          end

          def enabled?
            VSCode.perform do |ide|
              ide.within_vscode_editor do
                ide.click_menu_item('Accounts')
                has_text?('Settings Sync is On')
              end
            end
          end

          def go_to_synced_data_view
            VSCode.perform do |ide|
              ide.search_command_palette('Settings Sync: Show Synced Data')
            end
          end

          def open_remote_synced_data(setting_type)
            ui_metadata = get_ui_metadata(setting_type)

            return unless ui_metadata

            remote_sync_activity_selector = "div[aria-label='Sync Activity (Remote)']"
            list_row_selector = '.monaco-list-row'

            go_to_synced_data_view unless has_element?(remote_sync_activity_selector)

            VSCode.perform do |ide|
              ide.within_vscode_editor do
                within_element(remote_sync_activity_selector) do
                  # click on row to expand the list
                  click_element(list_row_selector, text: ui_metadata[:label], visible: true, wait: 10)
                  click_element(list_row_selector, text: ui_metadata[:file_name], visible: true, wait: 10)
                end
              end
            end
          end

          def has_opened_synced_data_item?(setting_type)
            ui_metadata = get_ui_metadata(setting_type)

            return unless ui_metadata

            VSCode.perform do |ide|
              ide.has_opened_file?(ui_metadata[:file_name])
            end
          end

          private

          def get_ui_metadata(setting_type)
            setting_type_to_ui_metadata_map.fetch(setting_type.to_sym, nil)
          end
        end
      end
    end
  end
end

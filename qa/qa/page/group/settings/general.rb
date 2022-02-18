# frozen_string_literal: true

module QA
  module Page
    module Group
      module Settings
        class General < QA::Page::Base
          include ::QA::Page::Settings::Common
          include Page::Component::VisibilitySetting
          include Page::Component::ConfirmModal
          include Page::Component::NamespaceSelect

          view 'app/views/groups/edit.html.haml' do
            element :permission_lfs_2fa_content
            element :advanced_settings_content
          end

          view 'app/views/groups/settings/_permissions.html.haml' do
            element :save_permissions_changes_button
          end

          view 'app/views/groups/settings/_general.html.haml' do
            element :group_name_field
            element :save_name_visibility_settings_button
          end

          view 'app/views/groups/settings/_lfs.html.haml' do
            element :lfs_checkbox
          end

          view 'app/views/shared/_allow_request_access.html.haml' do
            element :request_access_checkbox
          end

          view 'app/views/groups/settings/_two_factor_auth.html.haml' do
            element :require_2fa_checkbox
          end

          view 'app/views/groups/settings/_project_creation_level.html.haml' do
            element :project_creation_level_dropdown
          end

          def set_group_name(name)
            find_element(:group_name_field).send_keys([:command, 'a'], :backspace)
            find_element(:group_name_field).set name
          end

          def click_save_name_visibility_settings_button
            click_element(:save_name_visibility_settings_button)
          end

          def set_lfs_enabled
            expand_content(:permission_lfs_2fa_content)
            check_element(:lfs_checkbox, true)
            click_element(:save_permissions_changes_button)
          end

          def set_lfs_disabled
            expand_content(:permission_lfs_2fa_content)
            uncheck_element(:lfs_checkbox, true)
            click_element(:save_permissions_changes_button)
          end

          def set_request_access_enabled
            expand_content(:permission_lfs_2fa_content)
            check_element(:request_access_checkbox, true)
            click_element(:save_permissions_changes_button)
          end

          def set_request_access_disabled
            expand_content(:permission_lfs_2fa_content)
            uncheck_element(:request_access_checkbox, true)
            click_element(:save_permissions_changes_button)
          end

          def set_require_2fa_enabled
            expand_content(:permission_lfs_2fa_content)
            check_element(:require_2fa_checkbox, true)
            click_element(:save_permissions_changes_button)
          end

          def set_require_2fa_disabled
            expand_content(:permission_lfs_2fa_content)
            uncheck_element(:require_2fa_checkbox, true)
            click_element(:save_permissions_changes_button)
          end

          def set_project_creation_level(value)
            expand_content(:permission_lfs_2fa_content)
            select_element(:project_creation_level_dropdown, value)
            click_element(:save_permissions_changes_button)
          end

          def toggle_request_access
            expand_content(:permission_lfs_2fa_content)

            if find_element(:request_access_checkbox, visible: false).checked?
              uncheck_element(:request_access_checkbox, true)
            else
              check_element(:request_access_checkbox, true)
            end

            click_element(:save_permissions_changes_button)
          end

          def transfer_group(target_group, source_group)
            expand_content :advanced_settings_content

            select_namespace(target_group)
            click_element(:transfer_button)

            fill_confirmation_text(source_group)
            confirm_transfer
          end
        end
      end
    end
  end
end

QA::Page::Group::Settings::General.prepend_mod_with('Page::Group::Settings::General', namespace: QA)

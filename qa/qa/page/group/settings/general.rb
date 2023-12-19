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
            element 'permissions-settings'
            element 'advanced-settings-content'
          end

          view 'app/views/groups/settings/_permissions.html.haml' do
            element 'save-permissions-changes-button'
          end

          view 'app/views/groups/settings/_general.html.haml' do
            element 'group-name-field'
            element 'save-name-visibility-settings-button'
          end

          view 'app/views/groups/settings/_lfs.html.haml' do
            element 'lfs-checkbox'
          end

          view 'app/views/shared/_allow_request_access.html.haml' do
            element 'request-access-checkbox'
          end

          view 'app/views/groups/settings/_two_factor_auth.html.haml' do
            element 'require-2fa-checkbox'
          end

          view 'app/views/groups/settings/_project_creation_level.html.haml' do
            element 'project-creation-level-dropdown'
          end

          view 'app/views/groups/settings/_transfer.html.haml' do
            element 'transfer-group-content'
          end

          view 'app/assets/javascripts/groups/components/transfer_group_form.vue' do
            element 'transfer-group-button'
          end

          def set_group_name(name)
            find_element('group-name-field').send_keys([:command, 'a'], :backspace)
            find_element('group-name-field').set name
          end

          def click_save_name_visibility_settings_button
            click_element('save-name-visibility-settings-button')
          end

          def set_lfs_enabled
            expand_content('permissions-settings')
            check_element('lfs-checkbox', true)
            click_element('save-permissions-changes-button')
          end

          def set_lfs_disabled
            expand_content('permissions-settings')
            uncheck_element('lfs-checkbox', true)
            click_element('save-permissions-changes-button')
          end

          def set_request_access_enabled
            expand_content('permissions-settings')
            check_element('request-access-checkbox', true)
            click_element('save-permissions-changes-button')
          end

          def set_request_access_disabled
            expand_content('permissions-settings')
            uncheck_element('request-access-checkbox', true)
            click_element('save-permissions-changes-button')
          end

          def set_require_2fa_enabled
            expand_content('permissions-settings')
            check_element('require-2fa-checkbox', true)
            click_element('save-permissions-changes-button')
          end

          def set_require_2fa_disabled
            expand_content('permissions-settings')
            uncheck_element('require-2fa-checkbox', true)
            click_element('save-permissions-changes-button')
          end

          def set_project_creation_level(value)
            expand_content('permissions-settings')
            select_element('project-creation-level-dropdown', value)
            click_element('save-permissions-changes-button')
          end

          def toggle_request_access
            expand_content('permissions-settings')

            if find_element('request-access-checkbox', visible: false).checked?
              uncheck_element('request-access-checkbox', true)
            else
              check_element('request-access-checkbox', true)
            end

            click_element('save-permissions-changes-button')
          end

          def transfer_group(source_group, target_group)
            QA::Runtime::Logger.info "Transferring group: #{source_group.path} to target group: #{target_group.path}"

            expand_content('advanced-settings-content')

            scroll_to_transfer_group_content

            select_namespace(target_group.path)

            wait_for_enabled_transfer_group_button
            click_element('transfer-group-button')

            fill_confirmation_text(source_group.full_path)
            confirm_transfer
          end

          private

          def scroll_to_transfer_group_content
            retry_until(sleep_interval: 1, message: 'Waiting for transfer group content to display') do
              has_element?('transfer-group-content', wait: 3)
            end

            scroll_to_element 'transfer-group-content'
          end

          def wait_for_enabled_transfer_group_button
            retry_until(sleep_interval: 1, message: 'Waiting for transfer group button to be enabled') do
              has_element?('transfer-group-button', disabled: false, wait: 3)
            end
          end
        end
      end
    end
  end
end

QA::Page::Group::Settings::General.prepend_mod_with('Page::Group::Settings::General', namespace: QA)

# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class Advanced < Page::Base
          include QA::Page::Component::ConfirmModal
          include QA::Page::Component::DeleteModal
          include Component::NamespaceSelect

          view 'app/assets/javascripts/projects/components/shared/delete_button.vue' do
            element 'delete-button'
          end

          view 'app/views/projects/edit.html.haml' do
            element 'project-path-field'
            element 'change-path-button'
          end

          view 'app/views/projects/settings/_archive.html.haml' do
            element 'archive-project-link'
            element 'unarchive-project-link'
          end

          view 'app/views/projects/_export.html.haml' do
            element 'export-project-link'
            element 'download-export-link'
            element 'export-project-content'
          end

          view 'app/views/projects/_transfer.html.haml' do
            element 'transfer-project-content'
          end

          view 'app/assets/javascripts/projects/settings/components/transfer_project_form.vue' do
            element 'transfer-project-button'
          end

          def update_project_path_to(path)
            fill_project_path(path)
            click_change_path_button
          end

          def fill_project_path(path)
            fill_element 'project-path-field', path
          end

          def click_change_path_button
            click_element 'change-path-button'
          end

          def transfer_project!(project_name, namespace)
            QA::Runtime::Logger.info "Transferring project: #{project_name} to namespace: #{namespace}"

            scroll_to_transfer_project_content

            # Workaround for a failure to search when there are no spaces around the /
            # https://gitlab.com/gitlab-org/gitlab/-/issues/218965
            select_namespace(namespace.gsub(%r{([^\s])/([^\s])}, '\1 / \2'))

            wait_for_enabled_transfer_project_button

            click_element 'transfer-project-button'

            fill_confirmation_text(project_name)
            confirm_transfer
          end

          def click_export_project_link
            click_element 'export-project-link'
          end

          def click_download_export_link
            click_element 'download-export-link'
          end

          def has_download_export_link?(wait: Capybara.default_max_wait_time)
            has_element?('download-export-link', wait: wait)
          end

          def archive_project
            click_element 'archive-project-link'
            click_confirmation_ok_button
          end

          def unarchive_project
            click_element 'unarchive-project-link'
            click_confirmation_ok_button
          end

          def delete_project!(project_name)
            click_element 'delete-button'
            fill_confirmation_path(project_name)
            wait_for_delete_button_enabled
            confirm_delete
          end

          private

          def scroll_to_transfer_project_content
            retry_until(sleep_interval: 1, message: 'Waiting for transfer project content to display') do
              has_element?('transfer-project-content', wait: 3)
            end

            scroll_to_element 'transfer-project-content'
          end

          def wait_for_enabled_transfer_project_button
            retry_until(sleep_interval: 1, message: 'Waiting for transfer project button to be enabled') do
              has_element?('transfer-project-button', disabled: false, wait: 3)
            end
          end
        end
      end
    end
  end
end

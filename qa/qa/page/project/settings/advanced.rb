# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class Advanced < Page::Base
          include QA::Page::Component::ConfirmModal
          include Component::NamespaceSelect

          view 'app/assets/javascripts/vue_shared/components/confirm_danger/confirm_danger.vue' do
            element :confirm_danger_button
          end

          view 'app/views/projects/edit.html.haml' do
            element :project_path_field
            element :change_path_button
          end

          view 'app/views/projects/settings/_archive.html.haml' do
            element :archive_project_link
            element :unarchive_project_link
            element :archive_project_content
          end

          view 'app/views/projects/_export.html.haml' do
            element :export_project_link
            element :download_export_link
            element :export_project_content
          end

          def update_project_path_to(path)
            fill_project_path(path)
            click_change_path_button
          end

          def fill_project_path(path)
            fill_element :project_path_field, path
          end

          def click_change_path_button
            click_element :change_path_button
          end

          def transfer_project!(project_name, namespace)
            QA::Runtime::Logger.info "Transferring project: #{project_name} to namespace: #{namespace}"

            click_element_coordinates(:archive_project_content)

            # Workaround for a failure to search when there are no spaces around the /
            # https://gitlab.com/gitlab-org/gitlab/-/issues/218965
            select_namespace(namespace.gsub(%r{([^\s])/([^\s])}, '\1 / \2'))

            click_element(:confirm_danger_button)
            fill_confirmation_text(project_name)
            confirm_transfer
          end

          def click_export_project_link
            click_element :export_project_link
          end

          def click_download_export_link
            click_element :download_export_link
          end

          def has_download_export_link?
            has_element? :download_export_link
          end

          def archive_project
            click_element :archive_project_link
            click_confirmation_ok_button
          end

          def unarchive_project
            click_element :unarchive_project_link
            click_confirmation_ok_button
          end
        end
      end
    end
  end
end

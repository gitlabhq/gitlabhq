# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class Advanced < Page::Base
          include Component::Select2
          include Component::ConfirmModal

          view 'app/views/projects/edit.html.haml' do
            element :project_path_field
            element :change_path_button
          end

          view 'app/views/projects/_transfer.html.haml' do
            element :transfer_button
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

            expand_select_list

            # Workaround for a failure to search when there are no spaces around the /
            # https://gitlab.com/gitlab-org/gitlab/-/issues/218965
            search_and_select(namespace.gsub(%r{([^\s])/([^\s])}, '\1 / \2'))

            click_element(:transfer_button)
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
            page.accept_alert("Are you sure that you want to archive this project?") do
              click_element :archive_project_link
            end
          end

          def unarchive_project
            page.accept_alert("Are you sure that you want to unarchive this project?") do
              click_element :unarchive_project_link
            end
          end
        end
      end
    end
  end
end

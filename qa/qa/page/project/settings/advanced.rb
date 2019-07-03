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
            element :transfer_button
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

          def select_transfer_option(namespace)
            search_and_select(namespace)
          end

          def transfer_project!(project_name, namespace)
            expand_select_list
            select_transfer_option(namespace)
            click_element(:transfer_button)
            fill_confirmation_text(project_name)
            click_confirm_button
          end
        end
      end
    end
  end
end

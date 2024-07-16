# frozen_string_literal: true

module QA
  module Page
    module Search
      class Results < QA::Page::Base
        view 'app/views/search/results/_blob_data.html.haml' do
          element 'result-item-content'
          element 'file-title-content'
          element 'file-text-content'
        end

        view 'app/views/shared/projects/_project.html.haml' do
          element 'project-content'
        end

        def switch_to_code
          click_element('nav-item-link', submenu_item: 'Code')
        end

        def has_project_in_search_result?(project_name)
          has_element?('result-item-content', text: project_name)
        end

        def has_file_in_project?(file_name, project_name)
          within_element('result-item-content', text: project_name) do
            has_element?('file-title-content', text: file_name)
          end
        end

        def has_file_in_project_with_content?(file_text, file_path)
          within_element('result-item-content',
            text: file_path) do
            has_element?('file-text-content', text: file_text)
          end
        end

        def has_project?(project_name)
          has_element?('project-content', project_name: project_name)
        end
      end
    end
  end
end

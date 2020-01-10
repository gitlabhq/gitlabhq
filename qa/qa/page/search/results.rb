# frozen_string_literal: true

module QA::Page
  module Search
    class Results < QA::Page::Base
      view 'app/views/search/_category.html.haml' do
        element :code_tab
        element :projects_tab
      end

      view 'app/views/search/results/_blob_data.html.haml' do
        element :result_item_content
        element :file_title_content
        element :file_text_content
      end

      view 'app/views/shared/projects/_project.html.haml' do
        element :project
      end

      def switch_to_code
        switch_to_tab(:code_tab)
      end

      def switch_to_projects
        switch_to_tab(:projects_tab)
      end

      def has_file_in_project?(file_name, project_name)
        has_element?(:result_item_content, text: "#{project_name}: #{file_name}")
      end

      def has_file_with_content?(file_name, file_text)
        within_element_by_index(:result_item_content, 0) do
          break false unless has_element?(:file_title_content, text: file_name)

          has_element?(:file_text_content, text: file_text)
        end
      end

      def has_project?(project_name)
        has_element?(:project, project_name: project_name)
      end

      private

      def switch_to_tab(tab)
        retry_until do
          click_element(tab)
          has_active_element?(tab)
        end
      end
    end
  end
end

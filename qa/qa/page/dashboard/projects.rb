# frozen_string_literal: true

module QA
  module Page
    module Dashboard
      class Projects < Page::Base
        view 'app/views/shared/projects/_search_form.html.haml' do
          element :project_filter_form, required: true
        end

        def go_to_project(name)
          filter_by_name(name)

          find_link(text: name).click
        end

        def self.path
          '/'
        end

        def clear_project_filter
          fill_element(:project_filter_form, "")
        end

        private

        def filter_by_name(name)
          within_element(:project_filter_form) do
            fill_in :name, with: name
          end
        end
      end
    end
  end
end

QA::Page::Dashboard::Projects.prepend_if_ee('QA::EE::Page::Dashboard::Projects')

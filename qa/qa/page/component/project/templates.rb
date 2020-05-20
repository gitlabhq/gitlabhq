# frozen_string_literal: true

module QA
  module Page::Component
    module Project
      module Templates
        def use_template_for_project(project_name)
          within find_element(:template_option_row, text: project_name) do
            click_element :use_template_button
          end
        end
      end
    end
  end
end

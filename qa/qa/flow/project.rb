# frozen_string_literal: true

module QA
  module Flow
    module Project
      module_function

      def go_to_create_project_from_template
        Page::Project::New.perform(&:click_create_from_template_link)
      end
    end
  end
end

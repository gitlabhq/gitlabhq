# frozen_string_literal: true

module QA
  module Flow
    module Project
      module_function

      def go_to_create_project_from_template
        if Page::Project::NewExperiment.perform(&:shown?)
          Page::Project::NewExperiment.perform(&:click_create_from_template_link)
        else
          Page::Project::New.perform(&:click_create_from_template_tab)
        end
      end
    end
  end
end

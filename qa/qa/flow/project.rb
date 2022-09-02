# frozen_string_literal: true

module QA
  module Flow
    module Project
      extend self

      def go_to_create_project_from_template
        Page::Project::New.perform(&:click_create_from_template_link)
      end
    end
  end
end

QA::Flow::Project.prepend_mod_with('Flow::Project', namespace: QA)

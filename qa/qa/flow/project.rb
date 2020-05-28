# frozen_string_literal: true

module QA
  module Flow
    module Project
      module_function

      def add_member(project:, username:)
        project.visit!

        Page::Project::Menu.perform(&:click_members)

        Page::Project::Members.perform do |member_settings|
          member_settings.add_member(username)
        end
      end
    end
  end
end

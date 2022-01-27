# frozen_string_literal: true

module QA
  module Resource
    class ProjectBadge < BadgeBase
      def initialize
        super

        @link_url = "#{Runtime::Scenario.gitlab_address}/%{project_path}"
        @image_url = "#{Runtime::Scenario.gitlab_address}/%{project_path}/badges/%{default_branch}/pipeline.svg"
      end

      def fabricate!
        Page::Project::Menu.perform(&:go_to_general_settings)
        Page::Project::Settings::Main.perform(&:expand_badges_settings)

        super
      end
    end
  end
end

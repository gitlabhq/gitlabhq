module Gitlab
  module ChatCommands
    class IssueCommand < BaseCommand
      def self.available?(project)
        project.issues_enabled? && project.default_issues_tracker?
      end

      def collection
        project.issues
      end

      def readable?(issue)
        can?(current_user, :read_issue, issue)
      end
    end
  end
end

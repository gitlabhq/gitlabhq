module Gitlab
  module ChatCommands
    class IssueCommand < BaseCommand
      def self.available?(project)
        project.issues_enabled? && project.default_issues_tracker?
      end

      def collection
        IssuesFinder.new(current_user, project_id: project.id).execute
      end
    end
  end
end

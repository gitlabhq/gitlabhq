module Mattermost
  module Commands
    class IssueService < Mattermost::Commands::BaseService
      def available?
        project.issues_enabled? && project.default_issues_tracker?
      end

      def collection
        project.issues
      end

      def readable?(issue)
        can?(current_user, :read_issue, issue)
      end

      def present
        Mattermost::Presenter.issue
      end
    end
  end
end

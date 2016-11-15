module Mattermost
  module Commands
    class MergeRequestService < Mattermost::Commands::BaseService
      def available?
        project.issues_enabled? && project.default_issues_tracker?
      end

      def collection
        project.merge_requests
      end

      def readable?(_)
        can?(current_user, :read_merge_request, project)
      end

      def present
        Mattermost::Presenter.merge_request
      end
    end
  end
end

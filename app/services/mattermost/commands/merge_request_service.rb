module Mattermost
  module Commands
    class MergeRequestService < Mattermost::Commands::BaseService
      def self.available?(project)
        project.merge_requests_enabled?
      end

      def collection
        project.merge_requests
      end

      def readable?(_)
        can?(current_user, :read_merge_request, project)
      end
    end
  end
end

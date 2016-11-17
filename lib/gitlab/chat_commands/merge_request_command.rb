module Gitlab
  module ChatCommands
    class MergeRequestCommand < BaseCommand
      def self.available?(project)
        project.merge_requests_enabled?
      end

      def collection
        project.merge_requests
      end

      def readable?(merge_request)
        can?(current_user, :read_merge_request, merge_request)
      end
    end
  end
end

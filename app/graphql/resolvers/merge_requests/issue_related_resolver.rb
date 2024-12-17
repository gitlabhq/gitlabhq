# frozen_string_literal: true

module Resolvers
  module MergeRequests
    class IssueRelatedResolver < BaseResolver
      prepend ::MergeRequests::LookAheadPreloads

      type Types::MergeRequestType.connection_type, null: true

      def resolve_with_lookahead
        scoped_merge_requests = MergeRequest.id_in(
          ::Issues::ReferencedMergeRequestsService.new(container: resource.resource_parent, current_user: current_user)
            .referenced_merge_requests(resource)
            .map(&:id)
        )

        apply_lookahead(scoped_merge_requests)
      end

      private

      def resource
        object
      end
    end
  end
end

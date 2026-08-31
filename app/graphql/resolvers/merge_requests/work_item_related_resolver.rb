# frozen_string_literal: true

module Resolvers
  module MergeRequests
    class WorkItemRelatedResolver < IssueRelatedResolver # rubocop:disable Graphql/ResolverType -- Parent class defines the type
      extend ::Gitlab::Utils::Override

      override :resolve_with_lookahead
      def resolve_with_lookahead
        return ::MergeRequest.none if resource.group_level?

        ids = ::Issues::ReferencedMergeRequestsService
          .new(container: resource.project, current_user: current_user)
          .related_merge_request_ids(resource)

        apply_lookahead(::MergeRequest.id_in(ids))
      end

      private

      override :resource
      def resource
        object.work_item
      end
    end
  end
end

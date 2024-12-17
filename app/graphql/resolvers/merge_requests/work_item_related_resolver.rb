# frozen_string_literal: true

module Resolvers
  module MergeRequests
    class WorkItemRelatedResolver < IssueRelatedResolver # rubocop:disable Graphql/ResolverType -- Parent class defines the type
      extend ::Gitlab::Utils::Override

      override :resolve_with_lookahead
      def resolve_with_lookahead
        return ::MergeRequest.none if resource.group_level?

        super
      end

      private

      override :resource
      def resource
        object.work_item
      end
    end
  end
end

# frozen_string_literal: true

module Resolvers
  module Namespaces
    # rubocop:disable Graphql/ResolverType -- inherited from Resolvers::WorkItemsResolver
    class WorkItemsResolver < ::Resolvers::WorkItemsResolver
      def ready?(**args)
        return false if Feature.disabled?(:namespace_level_work_items, resource_parent)

        super
      end

      override :resolve_with_lookahead
      def resolve_with_lookahead(...)
        super
      rescue ::WorkItems::NamespaceWorkItemsFinder::FilterNotAvailableError => e
        raise Gitlab::Graphql::Errors::ArgumentError, e.message
      end

      private

      override :finder
      def finder(args)
        ::WorkItems::NamespaceWorkItemsFinder.new(
          current_user,
          args.merge(namespace_id: resource_parent)
        )
      end
    end
    # rubocop:enable Graphql/ResolverType
  end
end

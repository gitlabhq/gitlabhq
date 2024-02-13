# frozen_string_literal: true

module Resolvers
  module Namespaces
    # rubocop:disable Graphql/ResolverType -- inherited from Resolvers::WorkItemsResolver
    class WorkItemsResolver < ::Resolvers::WorkItemsResolver
      def ready?(**args)
        return false if Feature.disabled?(:namespace_level_work_items, resource_parent)

        super
      end

      private

      override :finder
      def finder(args)
        ::WorkItems::WorkItemsFinder.new(
          current_user,
          args.merge(group_id: resource_parent)
        )
      end
    end
    # rubocop:enable Graphql/ResolverType
  end
end

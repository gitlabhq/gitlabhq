# frozen_string_literal: true

module Resolvers
  module Namespaces
    # rubocop:disable Graphql/ResolverType -- inherited from Resolvers::WorkItemsResolver
    class WorkItemsResolver < ::Resolvers::WorkItemsResolver
      argument :include_ancestors, GraphQL::Types::Boolean,
        required: false,
        default_value: false,
        description: 'Include work items from ancestor groups.'

      argument :include_descendants, GraphQL::Types::Boolean,
        required: false,
        default_value: false,
        description: 'Include work items from descendant groups and projects.'

      argument :exclude_projects, GraphQL::Types::Boolean,
        required: false,
        default_value: false,
        description: 'Exclude work items from projects within the group.',
        experiment: { milestone: '17.5' }

      def ready?(**args)
        super && resource_parent.namespace_work_items_enabled?
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

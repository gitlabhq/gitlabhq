# frozen_string_literal: true

module Resolvers
  module Namespaces
    # rubocop:disable Graphql/ResolverType -- inherited from Resolvers::WorkItemsResolver
    class WorkItemsResolver < ::Resolvers::WorkItemsResolver
      include TimeFrameHelpers

      GROUP_NAMESPACE_ONLY_ARGS = %i[
        include_ancestors
        include_descendants
        exclude_projects
        timeframe
        exclude_group_work_items
        include_archived
      ].freeze

      argument :include_ancestors, GraphQL::Types::Boolean,
        required: false,
        default_value: false,
        description: 'Include work items from ancestor groups. Ignored for project namespaces.'

      argument :include_descendants, GraphQL::Types::Boolean,
        required: false,
        default_value: false,
        description: 'Include work items from descendant groups and projects. Ignored for project namespaces.'

      argument :exclude_projects, GraphQL::Types::Boolean,
        required: false,
        default_value: false,
        description: 'Exclude work items from projects within the group. Ignored for project namespaces.',
        experiment: { milestone: '17.5' }

      argument :exclude_group_work_items, GraphQL::Types::Boolean,
        required: false,
        default_value: false,
        description: 'Exclude group-level work items within the group and its descendants. ' \
          'Ignored for project namespaces and when use_namespace_traversal_ids_for_work_items_finder feature flag is ' \
          'enabled.',
        experiment: { milestone: '18.4' }

      argument :include_archived, GraphQL::Types::Boolean,
        required: false,
        default_value: false,
        description: 'Return work items from archived projects. Ignored for project namespaces.',
        experiment: { milestone: '18.5' }

      argument :timeframe, Types::TimeframeInputType,
        required: false,
        description: 'List items overlapping the given timeframe. Ignored for project namespaces.'

      def ready?(**args)
        return false if object.is_a?(::Namespaces::UserNamespace)

        validate_timeframe_limit!(args[:timeframe]) if group_namespace?

        super
      end

      private

      override :finder
      def finder(args)
        filtered_args = if group_namespace?
                          args[:non_archived] = !args.delete(:include_archived)
                          args.merge(group_id: resource_parent, **transform_timeframe_parameters(args))
                        else
                          # For project namespaces, exclude the group level args
                          args.except(*GROUP_NAMESPACE_ONLY_ARGS)
                        end

        ::WorkItems::WorkItemsFinder.new(current_user, filtered_args)
      end

      def group_namespace?
        object.is_a?(::Group)
      end
      strong_memoize_attr :group_namespace?
    end
    # rubocop:enable Graphql/ResolverType
  end
end

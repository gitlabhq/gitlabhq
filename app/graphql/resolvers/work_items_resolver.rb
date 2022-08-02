# frozen_string_literal: true

module Resolvers
  class WorkItemsResolver < BaseResolver
    include SearchArguments
    include LooksAhead

    type Types::WorkItemType.connection_type, null: true

    argument :iid, GraphQL::Types::String,
             required: false,
             description: 'IID of the issue. For example, "1".'
    argument :iids, [GraphQL::Types::String],
             required: false,
             description: 'List of IIDs of work items. For example, `["1", "2"]`.'
    argument :sort, Types::WorkItemSortEnum,
             description: 'Sort work items by this criteria.',
             required: false,
             default_value: :created_desc
    argument :state, Types::IssuableStateEnum,
             required: false,
             description: 'Current state of this work item.'
    argument :types, [Types::IssueTypeEnum],
             as: :issue_types,
             description: 'Filter work items by the given work item types.',
             required: false

    def resolve_with_lookahead(**args)
      # The project could have been loaded in batch by `BatchLoader`.
      # At this point we need the `id` of the project to query for issues, so
      # make sure it's loaded and not `nil` before continuing.
      parent = object.respond_to?(:sync) ? object.sync : object
      return WorkItem.none if parent.nil? || !parent.work_items_feature_flag_enabled?

      args[:iids] ||= [args.delete(:iid)].compact if args[:iid]
      args[:attempt_project_search_optimizations] = true if args[:search].present?

      finder = ::WorkItems::WorkItemsFinder.new(current_user, args)

      Gitlab::Graphql::Loaders::IssuableLoader.new(parent, finder).batching_find_all { |q| apply_lookahead(q) }
    end

    def ready?(**args)
      validate_anonymous_search_access! if args[:search].present?

      super
    end

    private

    def unconditional_includes
      [
        {
          project: [:project_feature, :group]
        },
        :author
      ]
    end
  end
end

Resolvers::WorkItemsResolver.prepend_mod_with('Resolvers::WorkItemsResolver')

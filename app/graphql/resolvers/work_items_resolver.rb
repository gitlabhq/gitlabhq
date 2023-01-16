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
      return WorkItem.none if resource_parent.nil?

      finder = ::WorkItems::WorkItemsFinder.new(current_user, prepare_finder_params(args))

      Gitlab::Graphql::Loaders::IssuableLoader.new(resource_parent, finder).batching_find_all { |q| apply_lookahead(q) }
    end

    private

    def preloads
      {
        work_item_type: :work_item_type,
        web_url: { project: { namespace: :route } },
        widgets: :work_item_type
      }
    end

    def nested_preloads
      {
        widgets: widget_preloads,
        user_permissions: { update_work_item: :assignees }
      }
    end

    def widget_preloads
      {
        last_edited_by: :last_edited_by,
        assignees: :assignees,
        parent: :work_item_parent,
        children: { work_item_children_by_created_at: [:author, { project: :project_feature }] },
        labels: :labels,
        milestone: :milestone
      }
    end

    def unconditional_includes
      [
        {
          project: [:project_feature, :group]
        },
        :author
      ]
    end

    def prepare_finder_params(args)
      params = super(args)
      params[:iids] ||= [params.delete(:iid)].compact if params[:iid]

      params
    end

    def resource_parent
      # The project could have been loaded in batch by `BatchLoader`.
      # At this point we need the `id` of the project to query for work items, so
      # make sure it's loaded and not `nil` before continuing.
      strong_memoize(:resource_parent) do
        object.respond_to?(:sync) ? object.sync : object
      end
    end
  end
end

Resolvers::WorkItemsResolver.prepend_mod_with('Resolvers::WorkItemsResolver')

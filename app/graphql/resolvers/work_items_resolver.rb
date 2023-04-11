# frozen_string_literal: true

module Resolvers
  class WorkItemsResolver < BaseResolver
    include SearchArguments
    include LooksAhead
    include ::WorkItems::SharedFilterArguments

    argument :iid,
      GraphQL::Types::String,
      required: false,
      description: 'IID of the work item. For example, "1".'
    argument :sort,
      Types::WorkItemSortEnum,
      description: 'Sort work items by criteria.',
      required: false,
      default_value: :created_desc

    type Types::WorkItemType.connection_type, null: true

    def resolve_with_lookahead(**args)
      return WorkItem.none if resource_parent.nil?

      finder = ::WorkItems::WorkItemsFinder.new(current_user, prepare_finder_params(args))

      Gitlab::Graphql::Loaders::IssuableLoader.new(resource_parent, finder).batching_find_all { |q| apply_lookahead(q) }
    end

    private

    def preloads
      {
        work_item_type: :work_item_type,
        web_url: { namespace: :route, project: [:project_namespace, { namespace: :route }] },
        widgets: { work_item_type: :enabled_widget_definitions }
      }
    end

    def nested_preloads
      {
        widgets: widget_preloads,
        user_permissions: { update_work_item: :assignees },
        project: { jira_import_status: { project: :jira_imports } },
        author: {
          location: { author: :user_detail },
          gitpod_enabled: { author: :user_preference }
        }
      }
    end

    def widget_preloads
      {
        last_edited_by: :last_edited_by,
        assignees: :assignees,
        parent: :work_item_parent,
        children: { work_item_children_by_relative_position: [:author, { project: :project_feature }] },
        labels: :labels,
        milestone: { milestone: [:project, :group] },
        subscribed: [:assignees, :award_emoji, { notes: [:author, :award_emoji] }],
        award_emoji: { award_emoji: :awardable }
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

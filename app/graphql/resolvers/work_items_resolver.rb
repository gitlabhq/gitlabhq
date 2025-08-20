# frozen_string_literal: true

module Resolvers
  class WorkItemsResolver < BaseResolver
    prepend ::WorkItems::LookAheadPreloads
    include SearchArguments
    include ::WorkItems::SharedFilterArguments
    include ::WorkItems::NonStableCursorSortOptions

    argument :iid,
      GraphQL::Types::String,
      required: false,
      description: 'IID of the work item. For example, "1".'
    argument :sort,
      Types::WorkItems::SortEnum,
      description: 'Sort work items by criteria.',
      required: false,
      default_value: :created_desc

    type Types::WorkItemType.connection_type, null: true

    def resolve_with_lookahead(**args)
      return WorkItem.none if resource_parent.nil?

      # Adding skip_type_authorization in the resolver while it is conditionally enabled.
      # It can be moved to the field definition once the feature flag is removed
      # Issue: https://gitlab.com/gitlab-org/gitlab/-/issues/548096
      context.scoped_set!(:skip_type_authorization, [:read_work_item]) if skip_field_authorization?

      finder = choose_finder(args)

      items = Gitlab::Graphql::Loaders::IssuableLoader
        .new(resource_parent, finder)
        .batching_find_all { |q| apply_lookahead(q) }

      if non_stable_cursor_sort?(args[:sort])
        # Certain complex sorts are not supported by the stable cursor pagination yet.
        # In these cases, we use offset pagination, so we return the correct connection.
        offset_pagination(items)
      else
        items
      end
    end

    private

    def choose_finder(args)
      if ::Feature.enabled?(:glql_es_integration, current_user) ||
          ::Feature.enabled?(:work_items_list_es_integration, current_user)
        advanced_finder = advanced_finder(args)

        return advanced_finder if advanced_finder.use_elasticsearch_finder?
      end

      finder(prepare_finder_params(args))
    end

    def advanced_finder(args)
      ::Search::AdvancedFinders::WorkItemsFinder.new(current_user, context, resource_parent, args)
    end

    # When we search on a group level, this finder is being overwritten in
    # app/graphql/resolvers/namespaces/work_items_resolver.rb:32
    def finder(args)
      ::WorkItems::WorkItemsFinder.new(current_user, args)
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
        obj = object.is_a?(::Namespaces::ProjectNamespace) ? object.project : object
        obj.respond_to?(:sync) ? obj.sync : obj
      end
    end

    def skip_field_authorization?
      Feature.enabled?(:authorize_issue_types_in_finder, resource_parent.root_ancestor, type: :gitlab_com_derisk)
    end
  end
end

Resolvers::WorkItemsResolver.prepend_mod

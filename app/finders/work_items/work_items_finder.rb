# frozen_string_literal: true

# WorkItem model inherits from Issue model. It's planned to be its extension
# with widgets support. Because WorkItems are internally Issues, WorkItemsFinder
# can be almost identical to IssuesFinder, except it should return instances of
# WorkItems instead of Issues
# Arguments:
#   klass - actual WorkItems class
#   current_user - currently logged in user, if any
#   params:
#     work_item_parent_ids: integer[] (list of work item ids)
#     ids: integer[] (list of work item ids)
#
module WorkItems
  class WorkItemsFinder < IssuesFinder
    include Gitlab::Utils::StrongMemoize
    include TimeFrameFilter

    ROOT_TRAVERSAL_IDS_SORTING_OPTIONS = %w[
      updated_asc updated_desc created_asc created_desc
    ].freeze

    def klass
      WorkItem
    end

    def params_class
      ::IssuesFinder::Params
    end

    private

    def filter_items(items)
      items = super(items)

      items = by_ids(items)
      items = by_widgets(items)
      items = by_timeframe(items, with_namespace_cte: with_namespace_cte)
      items = by_work_item_parent_ids(items)
      items = by_negated_work_item_parent_ids(items)

      by_parent_wildcard_id(items)
    end

    def by_parent(items)
      return super unless use_namespace_traversal_ids_filtering?

      items_within_hierarchy = items.within_namespace_hierarchy(ancestor_group)
                                    .with_group_level_and_project_issues_enabled(
                                      include_group_level_items: include_group_work_items?,
                                      exclude_projects: exclude_projects?
                                    )

      # If the state filter is not present in the params we manually add it to filter all available states
      # This is needed because state_id is required for index utilization
      # See: https://gitlab.com/gitlab-org/gitlab/-/issues/562319
      unless state_filter_passed?
        items_within_hierarchy = items_within_hierarchy.with_state(*klass.available_state_names)
      end

      items_within_hierarchy
    end

    def by_widgets(items)
      WorkItems::WidgetDefinition.available_widgets.each do |widget_class|
        widget_filter = widget_filter_for(widget_class)

        next unless widget_filter

        items = widget_filter.filter(items, params)
      end

      items
    end

    def by_ids(items)
      return items unless params[:ids].present?

      items.id_in(params[:ids])
    end

    def widget_filter_for(widget_class)
      "WorkItems::Widgets::Filters::#{widget_class.name.demodulize.camelize}".constantize
    rescue NameError
      nil
    end

    def by_work_item_parent_ids(items)
      work_item_parent_ids = params[:work_item_parent_ids]

      return items unless work_item_parent_ids.present?

      parent_ids = if params[:include_descendant_work_items]
                     ::Gitlab::WorkItems::WorkItemHierarchy.new(WorkItem.id_in(work_item_parent_ids))
                                                           .base_and_descendants
                                                           .select(:id)
                   else
                     work_item_parent_ids
                   end

      items.with_work_item_parent_ids(parent_ids)
    end

    def by_negated_work_item_parent_ids(items)
      not_work_item_parent_ids = not_params[:work_item_parent_ids]
      return items unless not_work_item_parent_ids.present?

      items.not_in_parent_ids(not_work_item_parent_ids)
    end

    def by_parent_wildcard_id(items)
      wildcard = params[:parent_wildcard_id]&.to_s&.downcase

      case wildcard
      when ::IssuableFinder::Params::FILTER_NONE
        items.no_parent
      when ::IssuableFinder::Params::FILTER_ANY
        items.any_parent
      else
        items
      end
    end

    def accessible_projects
      return if exclude_projects?
      return if params.group && !include_descendants? # group-level work items are not supported in CE

      projects = Project
        .public_or_visible_to_user(current_user, ProjectFeature.required_minimum_access_level(klass.base_class))
        .with_feature_available_for_user(klass.base_class, current_user)

      projects = projects.in_namespace(params.group.self_and_descendant_ids) if params.group && include_descendants?
      projects = projects.id_in(params[:projects]) if params[:projects]
      projects = projects.id_in(params[:project_id]) if params[:project_id]

      projects
    end
    strong_memoize_attr :accessible_projects

    def with_namespace_cte
      false
    end

    def user_can_access_subgroup_work_items?
      Ability.allowed?(current_user, :read_all_resources) || ancestor_group.member?(current_user)
    end

    def use_namespace_traversal_ids_filtering?
      return false unless params.group?
      return false unless ::Feature.enabled?(:use_namespace_traversal_ids_for_work_items_finder, current_user)
      return false unless include_descendants?
      return false unless user_can_access_subgroup_work_items?

      # For sub-groups it's performant enough to use the traversal_ids and sort in memory.
      return true unless params.group.root?

      # For root groups, we don't have an index on all columns that we support sorting for.
      # For all columns we don't have an index for, we need to fallback to the old query.
      sorting_covered_by_index?
    end

    def include_group_work_items?
      false
    end

    def state_filter_passed?
      params[:state].present? && params[:state].to_s != 'all'
    end

    def ancestor_group
      include_ancestors? ? params.group.root_ancestor : params.group
    end

    def include_descendants?
      params.fetch(:include_descendants, false)
    end
    strong_memoize_attr :include_descendants?

    def include_ancestors?
      params.fetch(:include_ancestors, false)
    end
    strong_memoize_attr :include_ancestors?

    def exclude_projects?
      params.fetch(:exclude_projects, false)
    end
    strong_memoize_attr :exclude_projects?

    def sorting_covered_by_index?
      return true if params[:sort].blank?

      sort_param = params[:sort].to_s
      sort_param.in?(ROOT_TRAVERSAL_IDS_SORTING_OPTIONS)
    end
  end
end

WorkItems::WorkItemsFinder.prepend_mod

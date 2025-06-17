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
#
module WorkItems
  class WorkItemsFinder < IssuesFinder
    include Gitlab::Utils::StrongMemoize
    include TimeFrameFilter

    def klass
      WorkItem
    end

    def params_class
      ::IssuesFinder::Params
    end

    private

    def filter_items(items)
      items = super(items)

      items = by_widgets(items)
      items = by_timeframe(items, with_namespace_cte: with_namespace_cte)

      by_work_item_parent_ids(items)
    end

    def by_widgets(items)
      WorkItems::WidgetDefinition.available_widgets.each do |widget_class|
        widget_filter = widget_filter_for(widget_class)

        next unless widget_filter

        items = widget_filter.filter(items, params)
      end

      items
    end

    def widget_filter_for(widget_class)
      "WorkItems::Widgets::Filters::#{widget_class.name.demodulize.camelize}".constantize
    rescue NameError
      nil
    end

    def by_work_item_parent_ids(items)
      work_item_parent_ids = params[:work_item_parent_ids]

      return items unless work_item_parent_ids.present?

      items.with_work_item_parent_ids(work_item_parent_ids)
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
  end
end

WorkItems::WorkItemsFinder.prepend_mod

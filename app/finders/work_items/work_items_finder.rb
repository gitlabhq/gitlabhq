# frozen_string_literal: true

# WorkItem model inherits from Issue model. It's planned to be its extension
# with widgets support. Because WorkItems are internally Issues, WorkItemsFinder
# can be almost identical to IssuesFinder, except it should return instances of
# WorkItems instead of Issues
module WorkItems
  class WorkItemsFinder < IssuesFinder
    include Gitlab::Utils::StrongMemoize

    def klass
      WorkItem
    end

    def params_class
      ::IssuesFinder::Params
    end

    private

    def filter_items(items)
      items = super(items)

      by_widgets(items)
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

    override :use_full_text_search?
    def use_full_text_search?
      return false if include_namespace_level_work_items?

      super
    end

    override :by_confidential
    def by_confidential(items)
      return super unless include_namespace_level_work_items?

      Issues::ConfidentialityFilter.new(
        current_user: current_user,
        params: original_params,
        parent: root_ancestor_group,
        assignee_filter: assignee_filter,
        related_groups: related_groups
      ).filter(items)
    end

    override :by_parent
    def by_parent(items)
      return super unless include_namespace_level_work_items?

      relations = [group_namespaces, project_namespaces].compact

      return items.none if relations.empty?

      namespaces = if relations.one?
                     relations.first
                   else
                     Namespace.from_union(relations, remove_duplicates: false)
                   end

      items.in_namespaces_with_cte(namespaces)
    end

    def group_namespaces
      return if params[:project_id] || params[:projects]

      related_groups_with_access.select(:id)
    end

    def related_groups_with_access
      # If the user is not signed in, we just return public groups
      return related_groups.public_to_user unless current_user

      # If the user is an admin or a member of the root group, they will have read access to all
      # work items in the subgroups so we can skip the expensive permissions check
      if Ability.allowed?(current_user, :read_all_resources) || root_ancestor_group.member?(current_user)
        return related_groups
      end

      Group.id_in(
        Group.groups_user_can(related_groups, current_user, :read_work_item, same_root: true)
      )
    end

    def related_groups
      if include_ancestors? && include_descendants?
        params.group.self_and_hierarchy
      elsif include_ancestors?
        params.group.self_and_ancestors
      elsif include_descendants?
        params.group.self_and_descendants
      else
        Group.id_in(params.group.id)
      end
    end
    strong_memoize_attr :related_groups

    def root_ancestor_group
      include_ancestors? ? params.group.root_ancestor : params.group
    end

    def project_namespaces
      return if !include_descendants? || exclude_projects?

      projects = Project.in_namespace(params.group.self_and_descendant_ids)
      projects = projects.id_in(params[:projects]) if params[:projects]

      projects
        .public_or_visible_to_user(current_user, ProjectFeature.required_minimum_access_level(klass.base_class))
        .with_feature_available_for_user(klass.base_class, current_user)
        .select(:project_namespace_id)
    end

    def include_namespace_level_work_items?
      params.group? && params.group.namespace_work_items_enabled?
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

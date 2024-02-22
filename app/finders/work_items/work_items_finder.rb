# frozen_string_literal: true

# WorkItem model inherits from Issue model. It's planned to be its extension
# with widgets support. Because WorkItems are internally Issues, WorkItemsFinder
# can be almost identical to IssuesFinder, except it should return instances of
# WorkItems instead of Issues
module WorkItems
  class WorkItemsFinder < IssuesFinder
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

    override :by_parent
    def by_parent(items)
      return super unless include_namespace_level_work_items?

      relations = [group_namespaces, project_namespaces].compact

      namespaces = if relations.one?
                     relations.first
                   else
                     Namespace.from_union(relations)
                   end

      items.in_namespaces(namespaces)
    end

    def include_namespace_level_work_items?
      params.group? && Feature.enabled?(:namespace_level_work_items, params.group)
    end
  end
end

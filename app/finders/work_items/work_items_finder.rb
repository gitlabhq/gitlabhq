# frozen_string_literal: true

# WorkItem model inherits from Issue model. It's planned to be its extension
# with widgets support. Because WorkItems are internally Issues, WorkItemsFinder
# can be almost identical to IssuesFinder, except it should return instances of
# WorkItems instead of Issues
module WorkItems
  class WorkItemsFinder < IssuesFinder
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

    def model_class
      WorkItem
    end
  end
end

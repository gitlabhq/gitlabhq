module EE
  module IssuesHelper
    def weight_dropdown_tag(issuable, opts = {}, &block)
      title = issuable.weight || 'Weight'
      additional_toggle_class = opts.delete(:toggle_class)
      options = {
        toggle_class: "js-weight-select #{additional_toggle_class}",
        dropdown_class: 'dropdown-menu-selectable dropdown-menu-weight',
        title: 'Select weight',
        placeholder: 'Search weight',
        data: {
          field_name: "#{issuable.class.model_name.param_key}[weight]",
          default_label: 'Weight'
        }
      }.deep_merge(opts)

      dropdown_tag(title, options: options) do
        capture(&block)
      end
    end

    def weight_dropdown_label(weight)
      if Issue.weight_options.include?(weight)
        weight
      else
        h(weight.presence || 'Weight')
      end
    end
  end
end

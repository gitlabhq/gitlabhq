module DropdownsHelper
  def dropdown_tag(toggle_text, options: {}, &block)
    content_tag :div, class: "dropdown #{options[:wrapper_class] if options.key?(:wrapper_class)}" do
      data_attr = { toggle: "dropdown" }

      if options.key?(:data)
        data_attr = options[:data].merge(data_attr)
      end

      dropdown_output = dropdown_toggle(toggle_text, data_attr, options)

      dropdown_output << content_tag(:div, class: "dropdown-menu dropdown-select #{options[:dropdown_class] if options.key?(:dropdown_class)}") do
        output = ""

        if options.key?(:title)
          output << dropdown_title(options[:title])
        end

        if options.key?(:filter)
          output << dropdown_filter(options[:placeholder])
        end

        output << content_tag(:div, class: "dropdown-content #{options[:content_class] if options.key?(:content_class)}") do
          capture(&block) if block && !options.key?(:footer_content)
        end

        if block && options[:footer_content]
          output << content_tag(:div, class: "dropdown-footer") do
            capture(&block)
          end
        end

        output << dropdown_loading

        output.html_safe
      end

      dropdown_output.html_safe
    end
  end

  def dropdown_toggle(toggle_text, data_attr, options = {})
    default_label = data_attr[:default_label]
    content_tag(:button, disabled: options[:disabled], class: "dropdown-menu-toggle #{options[:toggle_class] if options.key?(:toggle_class)}", id: (options[:id] if options.key?(:id)), type: "button", data: data_attr) do
      output = content_tag(:span, toggle_text, class: "dropdown-toggle-text #{'is-default' if toggle_text == default_label}")
      output << icon('chevron-down')
      output.html_safe
    end
  end

  def dropdown_title(title, options: {})
    content_tag :div, class: "dropdown-title" do
      title_output = ""

      if options.fetch(:back, false)
        title_output << content_tag(:button, class: "dropdown-title-button dropdown-menu-back", aria: { label: "Go back" }, type: "button") do
          icon('arrow-left')
        end
      end

      title_output << content_tag(:span, title)

      if options.fetch(:close, true)
        title_output << content_tag(:button, class: "dropdown-title-button dropdown-menu-close", aria: { label: "Close" }, type: "button") do
          icon('times', class: 'dropdown-menu-close-icon')
        end
      end

      title_output.html_safe
    end
  end

  def dropdown_input(placeholder, input_id: nil)
    content_tag :div, class: "dropdown-input" do
      filter_output = text_field_tag input_id, nil, class: "dropdown-input-field dropdown-no-filter", placeholder: placeholder, autocomplete: 'off'
      filter_output << icon('times', class: "dropdown-input-clear js-dropdown-input-clear", role: "button")

      filter_output.html_safe
    end
  end

  def dropdown_filter(placeholder, search_id: nil)
    content_tag :div, class: "dropdown-input" do
      filter_output = search_field_tag search_id, nil, class: "dropdown-input-field", placeholder: placeholder, autocomplete: 'off'
      filter_output << icon('search', class: "dropdown-input-search")
      filter_output << icon('times', class: "dropdown-input-clear js-dropdown-input-clear", role: "button")

      filter_output.html_safe
    end
  end

  def dropdown_content(&block)
    content_tag(:div, class: "dropdown-content") do
      if block
        capture(&block)
      end
    end
  end

  def dropdown_footer(add_content_class: false, &block)
    content_tag(:div, class: "dropdown-footer") do
      if add_content_class
        content_tag(:div, capture(&block), class: "dropdown-footer-content")
      else
        capture(&block)
      end
    end
  end

  def dropdown_loading
    content_tag :div, class: "dropdown-loading" do
      icon('spinner spin')
    end
  end
end

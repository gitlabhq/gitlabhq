module DropdownsHelper
  def dropdown_tag(toggle_text, options: {}, &block)
    content_tag :div, class: "dropdown" do
      data_attr = { toggle: "dropdown" }

      if options.has_key?(:data)
        data_attr = options[:data].merge(data_attr)
      end

      dropdown_output = dropdown_toggle(toggle_text, data_attr, options)

      dropdown_output << content_tag(:div, class: "dropdown-menu dropdown-select #{options[:dropdown_class] if options.has_key?(:dropdown_class)}") do
        output = ""

        if options.has_key?(:title)
          output << dropdown_title(options[:title])
        end

        if options.has_key?(:filter)
          output << dropdown_filter(options[:placeholder])
        end

        output << content_tag(:div, class: "dropdown-content") do
          capture(&block) if block && !options.has_key?(:footer_content)
        end

        if block && options.has_key?(:footer_content)
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

  def dropdown_toggle(toggle_text, data_attr, options)
    content_tag(:button, class: "dropdown-menu-toggle #{options[:toggle_class] if options.has_key?(:toggle_class)}", id: (options[:id] if options.has_key?(:id)), type: "button", data: data_attr) do
      output = content_tag(:span, toggle_text, class: "dropdown-toggle-text")
      output << icon('chevron-down')
      output.html_safe
    end
  end

  def dropdown_title(title, back: false)
    content_tag :div, class: "dropdown-title" do
      title_output = ""

      if back
        title_output << content_tag(:button, class: "dropdown-title-button dropdown-menu-back", aria: { label: "Go back" }, type: "button") do
          icon('arrow-left')
        end
      end

      title_output << content_tag(:span, title)

      title_output << content_tag(:button, class: "dropdown-title-button dropdown-menu-close", aria: { label: "Close" }, type: "button") do
        icon('times')
      end

      title_output.html_safe
    end
  end

  def dropdown_filter(placeholder)
    content_tag :div, class: "dropdown-input" do
      filter_output = search_field_tag nil, nil, class: "dropdown-input-field", placeholder: placeholder
      filter_output << icon('search')

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

  def dropdown_footer(&block)
    content_tag(:div, class: "dropdown-footer") do
      if block
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

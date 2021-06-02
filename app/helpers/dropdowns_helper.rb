# frozen_string_literal: true

module DropdownsHelper
  def dropdown_tag(toggle_text, options: {}, &block)
    content_tag :div, class: "dropdown #{options[:wrapper_class] if options.key?(:wrapper_class)}" do
      data_attr = { toggle: "dropdown" }

      if options.key?(:data)
        data_attr = options[:data].merge(data_attr)
      end

      dropdown_output = dropdown_toggle(toggle_text, data_attr, options)

      if options.key?(:toggle_link)
        dropdown_output = dropdown_toggle_link(toggle_text, data_attr, options)
      end

      content_tag_options = { class: "dropdown-menu dropdown-select #{options[:dropdown_class] if options.key?(:dropdown_class)}" }
      content_tag_options[:data] = { qa_selector: "#{options[:dropdown_qa_selector]}" } if options[:dropdown_qa_selector]

      dropdown_output << content_tag(:div, content_tag_options) do
        output = []

        if options.key?(:title)
          output << dropdown_title(options[:title])
        end

        if options.key?(:filter)
          output << dropdown_filter(options[:placeholder])
        end

        output << content_tag(:div, data: { qa_selector: "dropdown_list_content" }, class: "dropdown-content #{options[:content_class] if options.key?(:content_class)}") do
          capture(&block) if block && !options.key?(:footer_content)
        end

        if block && options[:footer_content]
          output << content_tag(:div, class: "dropdown-footer") do
            capture(&block)
          end
        end

        output << dropdown_loading
        output.join.html_safe
      end

      dropdown_output.html_safe
    end
  end

  def dropdown_toggle(toggle_text, data_attr, options = {})
    default_label = data_attr[:default_label]
    content_tag(:button, disabled: options[:disabled], class: "dropdown-menu-toggle #{options[:toggle_class] if options.key?(:toggle_class)}", id: (options[:id] if options.key?(:id)), type: "button", data: data_attr) do
      output = content_tag(:span, toggle_text, class: "dropdown-toggle-text #{'is-default' if toggle_text == default_label}")
      output << sprite_icon('chevron-down', css_class: "dropdown-menu-toggle-icon gl-top-3")
      output.html_safe
    end
  end

  def dropdown_toggle_link(toggle_text, data_attr, options = {})
    output = content_tag(:a, toggle_text, class: "dropdown-toggle-text #{options[:toggle_class] if options.key?(:toggle_class)}", id: (options[:id] if options.key?(:id)), data: data_attr)
    output.html_safe
  end

  def dropdown_title(title, options: {})
    has_back = options.fetch(:back, false)
    has_close = options.fetch(:close, true)

    container_class = %w[dropdown-title gl-display-flex]
    margin_class = []

    if has_back && has_close
      container_class << 'gl-justify-content-space-between'
    elsif has_back
      margin_class << 'gl-mr-auto'
    elsif has_close
      margin_class << 'gl-ml-auto'
    end

    container_class = container_class.join(' ')
    margin_class = margin_class.join(' ')

    content_tag :div, class: container_class do
      title_output = []

      if has_back
        title_output << content_tag(:button, class: "dropdown-title-button dropdown-menu-back " + margin_class, aria: { label: "Go back" }, type: "button") do
          sprite_icon('arrow-left')
        end
      end

      title_output << content_tag(:span, title, class: margin_class)

      if has_close
        title_output << content_tag(:button, class: "dropdown-title-button dropdown-menu-close " + margin_class, aria: { label: "Close" }, type: "button") do
          sprite_icon('close', size: 16, css_class: 'dropdown-menu-close-icon')
        end
      end

      title_output.join.html_safe
    end
  end

  def dropdown_filter(placeholder, search_id: nil)
    content_tag :div, class: "dropdown-input" do
      filter_output = search_field_tag search_id, nil, data: { qa_selector: "dropdown_input_field" }, id: nil, class: "dropdown-input-field", placeholder: placeholder, autocomplete: 'off'
      filter_output << sprite_icon('search', css_class: 'dropdown-input-search')
      filter_output << sprite_icon('close', size: 16, css_class: 'dropdown-input-clear js-dropdown-input-clear')

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
    spinner = loading_icon(container: true, size: "md", css_class: "gl-mt-7")
    content_tag(:div, spinner, class: "dropdown-loading")
  end
end

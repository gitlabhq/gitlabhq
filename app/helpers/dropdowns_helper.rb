module DropdownsHelper
  def dropdown_tag(toggle_text, id: nil, toggle_class: nil, dropdown_class: nil, title: false, filter: false, placeholder: "", footer_content: false, data: {}, &block)
    content_tag :div, class: "dropdown" do
      toggle_hash = data.merge({toggle: "dropdown"})

      dropdown_output = ""
      dropdown_output += content_tag :button, class: "dropdown-menu-toggle #{toggle_class}", id: id, type: "button", data: toggle_hash do
        output = toggle_text
        output << icon('chevron-down')
        output.html_safe
      end

      dropdown_output += content_tag :div, class: "dropdown-menu dropdown-select #{dropdown_class}" do
        output = ""

        if title
          output += content_tag :div, class: "dropdown-title" do
            title_output = content_tag(:span, title)

            title_output += content_tag :button, class: "dropdown-title-button dropdown-menu-close", aria: {label: "close"} do
              icon('times')
            end.html_safe
          end
        end

        if filter
          output += content_tag :div, class: "dropdown-input" do
            filter_output = search_field_tag nil, nil, class: "dropdown-input-field", placeholder: placeholder
            filter_output += icon('search')

            filter_output.html_safe
          end
        end

        output += content_tag :div, class: "dropdown-content" do
          capture(&block) if block && !footer_content
        end

        if block && footer_content
          output += content_tag :div, class: "dropdown-footer" do
            capture(&block)
          end
        end

        output += content_tag :div, class: "dropdown-loading" do
          icon('spinner spin')
        end

        output.html_safe
      end

      dropdown_output.html_safe
    end
  end
end

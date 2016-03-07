module DropdownsHelper
  def dropdown_tag(toggle_text, title: false, filter: false, placeholder: "", &block)
    content_tag :div, class: "dropdown" do
      dropdown_output = ""
      dropdown_output += content_tag :button, class: "dropdown-menu-toggle", type: "button", data: {toggle: "dropdown"} do
        output = toggle_text
        output << icon('chevron-down')
        output.html_safe
      end

      dropdown_output += content_tag :div, class: "dropdown-menu dropdown-select dropdown-menu-selectable" do
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
          capture(&block) if block
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

module FormHelper
  def form_errors(model, type: 'form')
    return unless model.errors.any?

    pluralized = 'error'.pluralize(model.errors.count)
    headline   = "The #{type} contains the following #{pluralized}:"

    content_tag(:div, class: 'alert alert-danger', id: 'error_explanation') do
      content_tag(:h4, headline) <<
        content_tag(:ul) do
          model.errors.full_messages
            .map { |msg| content_tag(:li, msg) }
            .join
            .html_safe
        end
    end
  end

  def issue_assignees_dropdown_options
    {
      toggle_class: 'js-user-search js-assignee-search js-multiselect js-save-user-data',
      title: 'Select assignee',
      filter: true,
      dropdown_class: 'dropdown-menu-user dropdown-menu-selectable dropdown-menu-assignee',
      placeholder: 'Search users',
      data: {
        first_user: current_user&.username,
        null_user: true,
        current_user: true,
        project_id: @project&.id,
        field_name: 'issue[assignee_ids][]',
        default_label: 'Unassigned',
        'max-select': 1,
        'dropdown-header': 'Assignee',
        multi_select: true,
        'input-meta': 'name',
        'always-show-selectbox': true,
        current_user_info: UserSerializer.new.represent(current_user)
      }
    }
  end
end

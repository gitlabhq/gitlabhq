module FormHelper
  def form_errors(model)
    return unless model.errors.any?

    pluralized = 'error'.pluralize(model.errors.count)
    headline   = "The form contains the following #{pluralized}:"

    content_tag(:div, class: 'alert alert-danger', id: 'error_explanation') do
      content_tag(:h4, headline) <<
        content_tag(:ul) do
          model.errors.full_messages.
            map { |msg| content_tag(:li, msg) }.
            join.
            html_safe
        end
    end
  end

  def issue_dropdown_options(issuable, has_multiple_assignees = true)
    options = {
      toggle_class: 'js-user-search js-assignee-search js-multiselect js-save-user-data',
      title: 'Select assignee',
      filter: true,
      dropdown_class: 'dropdown-menu-user dropdown-menu-selectable dropdown-menu-assignee',
      placeholder: 'Search users',
      data: {
        first_user: current_user&.username,
        null_user: true,
        current_user: true,
        project_id: issuable.project.try(:id),
        field_name: "#{issuable.class.model_name.param_key}[assignee_ids][]",
        default_label: 'Assignee',
        'max-select': 1,
        'dropdown-header': 'Assignee',
        multi_select: true,
        'input-meta': 'name',
        'always-show-selectbox': true,
        current_user_info: current_user.to_json(only: [:id, :name])
      }
    }

    if has_multiple_assignees
      options[:title] = 'Select assignee(s)'
      options[:data][:'dropdown-header'] = 'Assignee(s)'
      options[:data].delete(:'max-select')
    end

    options
  end
end

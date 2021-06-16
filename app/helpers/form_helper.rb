# frozen_string_literal: true

module FormHelper
  def form_errors(model, type: 'form', truncate: [])
    errors = model.errors

    return unless errors.any?

    headline = n_(
      'The %{type} contains the following error:',
      'The %{type} contains the following errors:',
      errors.count
    ) % { type: type }

    truncate = Array.wrap(truncate)

    tag.div(class: 'alert alert-danger', id: 'error_explanation') do
      tag.h4(headline) <<
        tag.ul do
          messages = errors.map do |error|
            attribute = error.attribute
            message = error.message

            message = html_escape_once(errors.full_message(attribute, message)).html_safe
            message = tag.span(message, class: 'str-truncated-100') if truncate.include?(attribute)

            tag.li(message)
          end

          messages.join.html_safe
        end
    end
  end

  def assignees_dropdown_options(issuable_type)
    dropdown_data = {
      toggle_class: 'js-user-search js-assignee-search js-multiselect js-save-user-data',
      title: 'Select assignee',
      filter: true,
      dropdown_class: 'dropdown-menu-user dropdown-menu-selectable dropdown-menu-assignee',
      placeholder: _('Search users'),
      data: {
        first_user: current_user&.username,
        null_user: true,
        current_user: true,
        project_id: (@target_project || @project)&.id,
        field_name: "#{issuable_type}[assignee_ids][]",
        default_label: 'Unassigned',
        'max-select': 1,
        'dropdown-header': 'Assignee',
        multi_select: true,
        'input-meta': 'name',
        'always-show-selectbox': true,
        current_user_info: UserSerializer.new.represent(current_user)
      }
    }

    type = issuable_type.to_s

    if type == 'issue' && issue_supports_multiple_assignees? ||
        type == 'merge_request' && merge_request_supports_multiple_assignees?
      dropdown_data = multiple_assignees_dropdown_options(dropdown_data)
    end

    dropdown_data
  end

  def reviewers_dropdown_options(issuable_type, iid = nil, target_branch = nil)
    dropdown_data = {
      toggle_class: 'js-reviewer-search js-multiselect js-save-user-data',
      title: 'Request review from',
      filter: true,
      dropdown_class: 'dropdown-menu-user dropdown-menu-selectable dropdown-menu-reviewer',
      placeholder: _('Search users'),
      data: {
        first_user: current_user&.username,
        null_user: true,
        current_user: true,
        project_id: (@target_project || @project)&.id,
        field_name: "#{issuable_type}[reviewer_ids][]",
        default_label: 'Unassigned',
        'max-select': 1,
        'dropdown-header': 'Reviewer',
        multi_select: true,
        'input-meta': 'name',
        'always-show-selectbox': true,
        current_user_info: UserSerializer.new.represent(current_user)
      }
    }

    if iid
      dropdown_data[:data][:iid] = iid
    end

    if target_branch
      dropdown_data[:data][:target_branch] = target_branch
    end

    if merge_request_supports_multiple_reviewers?
      dropdown_data = multiple_reviewers_dropdown_options(dropdown_data)
    end

    dropdown_data
  end

  # Overwritten
  def issue_supports_multiple_assignees?
    false
  end

  # Overwritten
  def merge_request_supports_multiple_assignees?
    false
  end

  # Overwritten
  def merge_request_supports_multiple_reviewers?
    false
  end

  private

  def multiple_assignees_dropdown_options(options)
    new_options = options.dup

    new_options[:title] = 'Select assignee(s)'
    new_options[:data][:'dropdown-header'] = 'Assignee(s)'
    new_options[:data].delete(:'max-select')

    new_options
  end

  def multiple_reviewers_dropdown_options(options)
    new_options = options.dup

    new_options[:title] = _('Select reviewer(s)')
    new_options[:data][:'dropdown-header'] = _('Reviewer(s)')
    new_options[:data].delete(:'max-select')

    new_options
  end
end

FormHelper.prepend_mod_with('FormHelper')

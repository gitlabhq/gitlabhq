# frozen_string_literal: true

module FormHelper
  def form_errors(model, type: 'form', truncate: [], custom_message: [], custom_headline: nil)
    errors = model.errors

    return unless errors.any?

    headline = custom_headline || (n_(
      'The %{type} contains the following error:',
      'The %{type} contains the following errors:',
      errors.count
    ) % { type: type })

    truncate = Array.wrap(truncate)

    messages = errors.map do |error|
      attribute = error.attribute

      message = errors.full_message(attribute, error.message)

      # When error message is custom and does not follow the default pattern
      # "<attribute name> <error message>" (e.g. "You have already reported this
      # user"), use the message as-is
      message = error.message if custom_message.include?(attribute)

      message = ERB::Util.html_escape_once(message).html_safe
      message = tag.span(message, class: 'str-truncated-100') if truncate.include?(attribute)
      message = append_help_page_link(message, error.options) if error.options[:help_page_url].present?

      tag.li(message)
    end.join.html_safe

    render Pajamas::AlertComponent.new(
      variant: :danger,
      title: headline,
      dismissible: false,
      alert_options: { id: 'error_explanation', class: 'gl-mb-5' }
    ) do |c|
      c.with_body do
        tag.ul(class: 'gl-pl-5 gl-mb-0') do
          messages
        end
      end
    end
  end

  def dropdown_max_select(data)
    if data[:'max-select'] && data[:'max-select'] < ::Issuable::MAX_NUMBER_OF_ASSIGNEES_OR_REVIEWERS
      data[:'max-select']
    else
      ::Issuable::MAX_NUMBER_OF_ASSIGNEES_OR_REVIEWERS
    end
  end

  def assignees_dropdown_options(issuable_type)
    dropdown_data = {
      toggle_class: 'js-user-search js-assignee-search js-multiselect js-save-user-data',
      title: _('Select assignee'),
      filter: true,
      dropdown_class: 'dropdown-menu-user dropdown-menu-selectable dropdown-menu-assignee',
      placeholder: _('Search users'),
      data: {
        first_user: current_user&.username,
        null_user: true,
        current_user: true,
        project_id: (@target_project || @project)&.id,
        field_name: "#{issuable_type}[assignee_ids][]",
        default_label: _('Unassigned'),
        'max-select': 1,
        'dropdown-header': s_('SearchToken|Assignee'),
        multi_select: true,
        'input-meta': 'name',
        'always-show-selectbox': true,
        current_user_info: UserSerializer.new.represent(current_user),
        testid: 'assignee-ids-dropdown-toggle'
      }
    }

    type = issuable_type.to_s

    if (type == 'issue' && issue_supports_multiple_assignees?) ||
        (type == 'merge_request' && merge_request_supports_multiple_assignees?)
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

    dropdown_data[:data][:iid] = iid if iid

    dropdown_data[:data][:target_branch] = target_branch if target_branch

    dropdown_data = multiple_reviewers_dropdown_options(dropdown_data) if merge_request_supports_multiple_reviewers?

    dropdown_data[:data].merge!(reviewers_dropdown_options_for_suggested_reviewers)
    dropdown_data
  end

  # Overwritten
  def reviewers_dropdown_options_for_suggested_reviewers
    {}
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

  def append_help_page_link(message, options)
    help_page_url = options[:help_page_url]
    help_link_text = options[:help_link_text] || _('Learn more.')

    help_link = link_to(
      help_link_text,
      help_page_url,
      target: '_blank',
      rel: 'noopener noreferrer'
    )

    message + " #{help_link}".html_safe
  end

  def multiple_assignees_dropdown_options(options)
    new_options = options.dup

    new_options[:title] = _('Select assignees')
    new_options[:data][:'dropdown-header'] = 'Assignees'
    new_options[:data][:'max-select'] = ::Issuable::MAX_NUMBER_OF_ASSIGNEES_OR_REVIEWERS

    new_options
  end

  def multiple_reviewers_dropdown_options(options)
    new_options = options.dup

    new_options[:title] = _('Select reviewers')
    new_options[:data][:'dropdown-header'] = _('Reviewers')

    new_options[:data][:'max-select'] = ::Issuable::MAX_NUMBER_OF_ASSIGNEES_OR_REVIEWERS

    new_options
  end
end

FormHelper.prepend_mod_with('FormHelper')

# frozen_string_literal: true

module IssuablesHelper
  include GitlabRoutingHelper

  def sidebar_gutter_toggle_icon
    sidebar_gutter_collapsed? ? icon('angle-double-left', { 'aria-hidden': 'true' }) : icon('angle-double-right', { 'aria-hidden': 'true' })
  end

  def sidebar_gutter_collapsed_class
    "right-sidebar-#{sidebar_gutter_collapsed? ? 'collapsed' : 'expanded'}"
  end

  def sidebar_gutter_tooltip_text
    sidebar_gutter_collapsed? ? _('Expand sidebar') : _('Collapse sidebar')
  end

  def sidebar_assignee_tooltip_label(issuable)
    if issuable.assignee
      issuable.assignee.name
    else
      issuable.allows_multiple_assignees? ? _('Assignee(s)') : _('Assignee')
    end
  end

  def sidebar_milestone_tooltip_label(milestone)
    if milestone && milestone[:due_date]
      "#{milestone[:title]}<br/>#{sidebar_milestone_remaining_days(milestone)}"
    else
      _('Milestone') + (milestone ? "<br/>#{milestone[:title]}" : "")
    end
  end

  def sidebar_milestone_remaining_days(milestone)
    due_date_remaining_days(due_date: milestone[:due_date], start_date: milestone[:start_date]) if milestone[:due_date]
  end

  def sidebar_due_date_tooltip_label(due_date)
    _('Due date') + (due_date ? "<br/>#{due_date_remaining_days(due_date)}" : "")
  end

  def due_date_remaining_days(due_date, start_date = nil)
    "#{due_date.to_s(:medium)} (#{remaining_days_in_words(due_date: due_date, start_date: start_date)})"
  end

  def sidebar_label_filter_path(base_path, label_name)
    query_params = {label_name: [label_name]}.to_query

    "#{base_path}?#{query_params}"
  end

  def multi_label_name(current_labels, default_label)
    if current_labels && current_labels.any?
      title = current_labels.first.try(:title) || current_labels.first[:title]

      if current_labels.size > 1
        "#{title} +#{current_labels.size - 1} more"
      else
        title
      end
    else
      default_label
    end
  end

  def issuable_json_path(issuable)
    project = issuable.project

    if issuable.is_a?(MergeRequest)
      project_merge_request_path(project, issuable.iid, :json)
    else
      project_issue_path(project, issuable.iid, :json)
    end
  end

  def serialize_issuable(issuable, serializer: nil)
    serializer_klass = case issuable
                       when Issue
                         IssueSerializer
                       when MergeRequest
                         MergeRequestSerializer
                       end

    serializer_klass
      .new(current_user: current_user, project: issuable.project)
      .represent(issuable, serializer: serializer)
      .to_json
  end

  def template_dropdown_tag(issuable, &block)
    title = selected_template(issuable) || "Choose a template"
    options = {
      toggle_class: 'js-issuable-selector',
      title: title,
      filter: true,
      placeholder: 'Filter',
      footer_content: true,
      data: {
        data: issuable_templates(issuable),
        field_name: 'issuable_template',
        selected: selected_template(issuable),
        project_path: ref_project.path,
        namespace_path: ref_project.namespace.full_path
      }
    }

    dropdown_tag(title, options: options) do
      capture(&block)
    end
  end

  def users_dropdown_label(selected_users)
    case selected_users.length
    when 0
      "Unassigned"
    when 1
      selected_users[0].name
    else
      "#{selected_users[0].name} + #{selected_users.length - 1} more"
    end
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def user_dropdown_label(user_id, default_label)
    return default_label if user_id.nil?
    return "Unassigned" if user_id == "0"

    user = User.find_by(id: user_id)

    if user
      user.name
    else
      default_label
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # rubocop: disable CodeReuse/ActiveRecord
  def project_dropdown_label(project_id, default_label)
    return default_label if project_id.nil?
    return "Any project" if project_id == "0"

    project = Project.find_by(id: project_id)

    if project
      project.full_name
    else
      default_label
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # rubocop: disable CodeReuse/ActiveRecord
  def group_dropdown_label(group_id, default_label)
    return default_label if group_id.nil?
    return "Any group" if group_id == "0"

    group = ::Group.find_by(id: group_id)

    if group
      group.full_name
    else
      default_label
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def milestone_dropdown_label(milestone_title, default_label = "Milestone")
    title =
      case milestone_title
      when Milestone::Upcoming.name then Milestone::Upcoming.title
      when Milestone::Started.name then Milestone::Started.title
      else milestone_title.presence
      end

    h(title || default_label)
  end

  def to_url_reference(issuable)
    case issuable
    when Issue
      link_to issuable.to_reference, issue_url(issuable)
    when MergeRequest
      link_to issuable.to_reference, merge_request_url(issuable)
    else
      issuable.to_reference
    end
  end

  def issuable_meta(issuable, project, text)
    output = []
    output << "Opened #{time_ago_with_tooltip(issuable.created_at)} by ".html_safe

    output << content_tag(:strong) do
      author_output = link_to_member(project, issuable.author, size: 24, mobile_classes: "d-none d-sm-inline")
      author_output << link_to_member(project, issuable.author, size: 24, by_username: true, avatar: false, mobile_classes: "d-block d-sm-none")

      if status = user_status(issuable.author)
        author_output << "#{status}".html_safe
      end

      author_output
    end

    output << content_tag(:span, (issuable_first_contribution_icon if issuable.first_contribution?), class: 'has-tooltip', title: _('1st contribution!'))

    output << content_tag(:span, (issuable.task_status if issuable.tasks?), id: "task_status", class: "d-none d-sm-none d-md-inline-block prepend-left-8")
    output << content_tag(:span, (issuable.task_status_short if issuable.tasks?), id: "task_status_short", class: "d-md-none")

    output.join.html_safe
  end

  def issuable_labels_tooltip(labels, limit: 5)
    first, last = labels.partition.with_index { |_, i| i < limit  }

    if labels && labels.any?
      label_names = first.collect { |l| l[:title] }
      label_names << "and #{last.size} more" unless last.empty?

      label_names.join(', ')
    else
      _("Labels")
    end
  end

  def issuables_state_counter_text(issuable_type, state, display_count)
    titles = {
      opened: "Open"
    }

    state_title = titles[state] || state.to_s.humanize
    html = content_tag(:span, state_title)

    if display_count
      count = issuables_count_for_state(issuable_type, state)
      html << " " << content_tag(:span, number_with_delimiter(count), class: 'badge badge-pill')
    end

    html.html_safe
  end

  def issuable_first_contribution_icon
    content_tag(:span, class: 'fa-stack') do
      concat(icon('certificate', class: "fa-stack-2x"))
      concat(content_tag(:strong, '1', class: 'fa-inverse fa-stack-1x'))
    end
  end

  def assigned_issuables_count(issuable_type)
    case issuable_type
    when :issues
      current_user.assigned_open_issues_count
    when :merge_requests
      current_user.assigned_open_merge_requests_count
    else
      raise ArgumentError, "invalid issuable `#{issuable_type}`"
    end
  end

  def issuable_reference(issuable)
    @show_full_reference ? issuable.to_reference(full: true) : issuable.to_reference(@group || @project)
  end

  def issuable_initial_data(issuable)
    data = {
      endpoint: issuable_path(issuable),
      updateEndpoint: "#{issuable_path(issuable)}.json",
      canUpdate: can?(current_user, :"update_#{issuable.to_ability_name}", issuable),
      canDestroy: can?(current_user, :"destroy_#{issuable.to_ability_name}", issuable),
      issuableRef: issuable.to_reference,
      markdownPreviewPath: preview_markdown_path(parent),
      markdownDocsPath: help_page_path('user/markdown'),
      markdownVersion: issuable.cached_markdown_version,
      issuableTemplates: issuable_templates(issuable),
      initialTitleHtml: markdown_field(issuable, :title),
      initialTitleText: issuable.title,
      initialDescriptionHtml: markdown_field(issuable, :description),
      initialDescriptionText: issuable.description,
      initialTaskStatus: issuable.task_status
    }

    if parent.is_a?(Group)
      data[:groupPath] = parent.path
    else
      data.merge!(projectPath: ref_project.path, projectNamespace: ref_project.namespace.full_path)
    end

    data.merge!(updated_at_by(issuable))

    data
  end

  def updated_at_by(issuable)
    return {} unless issuable.edited?

    {
      updatedAt: issuable.last_edited_at.to_time.iso8601,
      updatedBy: {
        name: issuable.last_edited_by.name,
        path: user_path(issuable.last_edited_by)
      }
    }
  end

  def issuables_count_for_state(issuable_type, state)
    Gitlab::IssuablesCountForState.new(finder)[state]
  end

  def close_issuable_path(issuable)
    issuable_path(issuable, close_reopen_params(issuable, :close))
  end

  def reopen_issuable_path(issuable)
    issuable_path(issuable, close_reopen_params(issuable, :reopen))
  end

  def close_reopen_issuable_path(issuable, should_inverse = false)
    issuable.closed? ^ should_inverse ? reopen_issuable_path(issuable) : close_issuable_path(issuable)
  end

  def issuable_path(issuable, *options)
    polymorphic_path(issuable, *options)
  end

  def issuable_url(issuable, *options)
    case issuable
    when Issue
      issue_url(issuable, *options)
    when MergeRequest
      merge_request_url(issuable, *options)
    end
  end

  def issuable_button_visibility(issuable, closed)
    return 'hidden' if issuable_button_hidden?(issuable, closed)
  end

  def issuable_button_hidden?(issuable, closed)
    case issuable
    when Issue
      issue_button_hidden?(issuable, closed)
    when MergeRequest
      merge_request_button_hidden?(issuable, closed)
    end
  end

  def issuable_close_reopen_button_method(issuable)
    case issuable
    when Issue
      ''
    when MergeRequest
      'put'
    end
  end

  def issuable_author_is_current_user(issuable)
    issuable.author == current_user
  end

  def issuable_display_type(issuable)
    issuable.model_name.human.downcase
  end

  def has_filter_bar_param?
    finder.class.scalar_params.any? { |p| params[p].present? }
  end

  private

  def sidebar_gutter_collapsed?
    cookies[:collapsed_gutter] == 'true'
  end

  def issuable_templates(issuable)
    @issuable_templates ||=
      case issuable
      when Issue
        ref_project.repository.issue_template_names
      when MergeRequest
        ref_project.repository.merge_request_template_names
      end
  end

  def selected_template(issuable)
    params[:issuable_template] if issuable_templates(issuable).any? { |template| template[:name] == params[:issuable_template] }
  end

  def close_reopen_params(issuable, action)
    {
      issuable.model_name.to_s.underscore => { state_event: action }
    }.tap do |params|
      params[:format] = :json if issuable.is_a?(Issue)
    end
  end

  def labels_path
    if @project
      project_labels_path(@project)
    elsif @group
      group_labels_path(@group)
    end
  end

  def issuable_sidebar_options(sidebar_data)
    {
      endpoint: "#{sidebar_data[:issuable_json_path]}?serializer=sidebar_extras",
      toggleSubscriptionEndpoint: sidebar_data[:toggle_subscription_path],
      moveIssueEndpoint: sidebar_data[:move_issue_path],
      projectsAutocompleteEndpoint: sidebar_data[:projects_autocomplete_path],
      editable: sidebar_data[:can_edit],
      currentUser: sidebar_data[:current_user],
      rootPath: root_path,
      fullPath: sidebar_data[:project_full_path]
    }
  end

  def parent
    @project || @group
  end
end

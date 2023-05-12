# frozen_string_literal: true

module IssuablesHelper
  include GitlabRoutingHelper
  include IssuablesDescriptionTemplatesHelper
  include ::Sidebars::Concerns::HasPill

  def sidebar_gutter_toggle_icon
    content_tag(:span, class: 'js-sidebar-toggle-container gl-button-text', data: { is_expanded: !sidebar_gutter_collapsed? }) do
      sprite_icon('chevron-double-lg-left', css_class: "js-sidebar-expand #{'hidden' unless sidebar_gutter_collapsed?}") +
      sprite_icon('chevron-double-lg-right', css_class: "js-sidebar-collapse #{'hidden' if sidebar_gutter_collapsed?}")
    end
  end

  def sidebar_gutter_collapsed_class(is_merge_request_with_flag)
    return "right-sidebar-expanded" if is_merge_request_with_flag

    "right-sidebar-#{sidebar_gutter_collapsed? ? 'collapsed' : 'expanded'}"
  end

  def sidebar_gutter_tooltip_text
    sidebar_gutter_collapsed? ? _('Expand sidebar') : _('Collapse sidebar')
  end

  def assignees_label(issuable, include_value: true)
    assignees = issuable.assignees

    if include_value
      sanitized_list = sanitize_name(issuable.assignee_list)
      ns_('NotificationEmail|Assignee: %{users}', 'NotificationEmail|Assignees: %{users}', assignees.count) % { users: sanitized_list }
    else
      ns_('NotificationEmail|Assignee', 'NotificationEmail|Assignees', assignees.count)
    end
  end

  def sidebar_milestone_tooltip_label(milestone)
    return _('Milestone') unless milestone.present?

    [escape_once(milestone[:title]), sidebar_milestone_remaining_days(milestone) || _('Milestone')].join('<br/>')
  end

  def sidebar_milestone_remaining_days(milestone)
    due_date_with_remaining_days(milestone[:due_date], milestone[:start_date])
  end

  def sidebar_due_date_tooltip_label(due_date)
    [_('Due date'), due_date_with_remaining_days(due_date)].compact.join('<br/>')
  end

  def due_date_with_remaining_days(due_date, start_date = nil)
    return unless due_date

    "#{due_date.to_s(:medium)} (#{remaining_days_in_words(due_date, start_date)})"
  end

  def multi_label_name(current_labels, default_label)
    return default_label if current_labels.blank?

    title = current_labels.first.try(:title) || current_labels.first[:title]

    if current_labels.size > 1
      "#{title} +#{current_labels.size - 1} more"
    else
      title
    end
  end

  def serialize_issuable(issuable, opts = {})
    serializer_klass = case issuable
                       when Issue
                         IssueSerializer
                       when MergeRequest
                         MergeRequestSerializer
                       end

    serializer_klass
      .new(current_user: current_user, project: issuable.project)
      .represent(issuable, opts)
      .to_json
  end

  def users_dropdown_label(selected_users)
    case selected_users.length
    when 0
      _('Unassigned')
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

  def issuable_meta_author_status(author)
    return "" unless author&.status&.customized? && status = user_status(author)

    status.to_s.html_safe
  end

  def issuable_meta(issuable, project)
    output = []

    if issuable.respond_to?(:work_item_type) && WorkItems::Type::WI_TYPES_WITH_CREATED_HEADER.include?(issuable.issue_type)
      output << content_tag(:span, sprite_icon(issuable.work_item_type.icon_name.to_s, css_class: 'gl-icon gl-vertical-align-middle gl-text-gray-500'), class: 'gl-mr-2', aria: { hidden: 'true' })
      output << content_tag(:span, s_('IssuableStatus|%{wi_type} created %{created_at} by ').html_safe % { wi_type: IntegrationsHelper.integration_issue_type(issuable.issue_type), created_at: time_ago_with_tooltip(issuable.created_at) }, class: 'gl-mr-2')
    else
      output << content_tag(:span, s_('IssuableStatus|Created %{created_at} by').html_safe % { created_at: time_ago_with_tooltip(issuable.created_at) }, class: 'gl-mr-2')
    end

    if issuable.is_a?(Issue) && issuable.service_desk_reply_to
      output << "#{html_escape(issuable.present(current_user: current_user).service_desk_reply_to)} via "
    end

    output << content_tag(:strong) do
      author_output = link_to_member(project, issuable.author, size: 24, mobile_classes: "d-none d-sm-inline-block")
      author_output << link_to_member(project, issuable.author, size: 24, by_username: true, avatar: false, mobile_classes: "d-inline d-sm-none")

      author_output << issuable_meta_author_slot(issuable.author, css_class: 'ml-1')
      author_output << issuable_meta_author_status(issuable.author)

      author_output
    end

    if access = project.team.human_max_access(issuable.author_id)
      output << content_tag(:span, access, class: "user-access-role has-tooltip d-none d-xl-inline-block gl-ml-3 ", title: _("This user has the %{access} role in the %{name} project.") % { access: access.downcase, name: project.name })
    elsif project.team.contributor?(issuable.author_id)
      output << content_tag(:span, _("Contributor"), class: "user-access-role has-tooltip d-none d-xl-inline-block gl-ml-3", title: _("This user has previously committed to the %{name} project.") % { name: project.name })
    end

    output << content_tag(:span, (sprite_icon('first-contribution', css_class: 'gl-icon gl-vertical-align-middle') if issuable.first_contribution?), class: 'has-tooltip gl-ml-2', title: _('1st contribution!'))

    output.join.html_safe
  end

  # This is a dummy method, and has an override defined in ee
  def issuable_meta_author_slot(author, css_class: nil)
    nil
  end

  def issuables_state_counter_text(issuable_type, state, display_count)
    titles = {
      opened: _("Open"),
      closed: _("Closed"),
      merged: _("Merged"),
      all: _("All")
    }
    state_title = titles[state] || state.to_s.humanize
    html = content_tag(:span, state_title)

    return html.html_safe unless display_count

    count = issuables_count_for_state(issuable_type, state)
    if count != -1
      html << " " << gl_badge_tag(format_count(issuable_type, count, Gitlab::IssuablesCountForState::THRESHOLD), { variant: :muted, size: :sm }, { class: "gl-tab-counter-badge gl-display-none gl-sm-display-inline-flex" })
    end

    html.html_safe
  end

  def assigned_issuables_count(issuable_type)
    case issuable_type
    when :issues
      ::Users::AssignedIssuesCountService.new(
        current_user: current_user,
        max_limit: User::MAX_LIMIT_FOR_ASSIGNEED_ISSUES_COUNT
      ).count
    when :merge_requests
      current_user.assigned_open_merge_requests_count
    else
      raise ArgumentError, "invalid issuable `#{issuable_type}`"
    end
  end

  def assigned_open_issues_count_text
    count = assigned_issuables_count(:issues)

    if count > User::MAX_LIMIT_FOR_ASSIGNEED_ISSUES_COUNT - 1
      "#{count - 1}+"
    else
      count.to_s
    end
  end

  def issuable_reference(issuable)
    @show_full_reference ? issuable.to_reference(full: true) : issuable.to_reference(@group || @project)
  end

  def issuable_project_reference(issuable)
    "#{issuable.project.full_name} #{issuable.to_reference}"
  end

  def issuable_initial_data(issuable)
    data = {
      endpoint: issuable_path(issuable),
      updateEndpoint: "#{issuable_path(issuable)}.json",
      canUpdate: can?(current_user, :"update_#{issuable.to_ability_name}", issuable),
      canDestroy: can?(current_user, :"destroy_#{issuable.to_ability_name}", issuable),
      issuableRef: issuable.to_reference,
      markdownPreviewPath: preview_markdown_path(parent, target_type: issuable.model_name, target_id: issuable.iid),
      markdownDocsPath: help_page_path('user/markdown'),
      lockVersion: issuable.lock_version,
      state: issuable.state,
      issuableTemplateNamesPath: template_names_path(parent, issuable),
      initialTitleHtml: markdown_field(issuable, :title),
      initialTitleText: issuable.title,
      initialDescriptionHtml: markdown_field(issuable, :description),
      initialDescriptionText: issuable.description,
      initialTaskCompletionStatus: issuable.task_completion_status
    }
    data.merge!(issue_only_initial_data(issuable))
    data.merge!(path_data(parent))
    data.merge!(updated_at_by(issuable))

    data
  end

  def issue_only_initial_data(issuable)
    return {} unless issuable.is_a?(Issue)

    {
      hasClosingMergeRequest: issuable.merge_requests_count(current_user) != 0,
      issueType: issuable.issue_type,
      zoomMeetingUrl: ZoomMeeting.canonical_meeting_url(issuable),
      sentryIssueIdentifier: SentryIssue.find_by(issue: issuable)&.sentry_issue_identifier, # rubocop:disable CodeReuse/ActiveRecord
      iid: issuable.iid.to_s,
      isHidden: issue_hidden?(issuable),
      canCreateIncident: create_issue_type_allowed?(issuable.project, :incident),
      **incident_only_initial_data(issuable)
    }
  end

  def incident_only_initial_data(issue)
    return {} unless issue.incident_type_issue?

    {
      hasLinkedAlerts: issue.alert_management_alerts.any?,
      canUpdateTimelineEvent: can?(current_user, :admin_incident_management_timeline_event, issue),
      currentPath: url_for(safe_params),
      currentTab: safe_params[:incident_tab]
    }
  end

  def path_data(parent)
    return { groupPath: parent.path } if parent.is_a?(Group)

    {
      projectPath: ref_project.path,
      projectId: ref_project.id,
      projectNamespace: ref_project.namespace.full_path
    }
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
    Gitlab::IssuablesCountForState.new(finder, fast_fail: true, store_in_redis_cache: true)[state]
  end

  def close_issuable_path(issuable)
    issuable_path(issuable, close_reopen_params(issuable, :close))
  end

  def reopen_issuable_path(issuable)
    issuable_path(issuable, close_reopen_params(issuable, :reopen))
  end

  def issuable_path(issuable, *options)
    polymorphic_path(issuable, *options)
  end

  def issuable_author_is_current_user(issuable)
    issuable.author == current_user
  end

  def issuable_display_type(issuable)
    case issuable
    when Issue
      issuable.issue_type.downcase
    when MergeRequest
      issuable.model_name.human.downcase
    end
  end

  def has_filter_bar_param?
    finder.class.scalar_params.any? { |p| params[p].present? }
  end

  def assignee_sidebar_data(assignee, merge_request: nil)
    { avatar_url: assignee.avatar_url, name: assignee.name, username: assignee.username }.tap do |data|
      data[:can_merge] = merge_request.can_be_merged_by?(assignee) if merge_request
      data[:availability] = assignee.status.availability if assignee.association(:status).loaded? && assignee.status&.availability
    end
  end

  def reviewer_sidebar_data(reviewer, merge_request: nil)
    { avatar_url: reviewer.avatar_url, name: reviewer.name, username: reviewer.username }.tap do |data|
      data[:can_merge] = merge_request.can_be_merged_by?(reviewer) if merge_request
    end
  end

  def issuable_squash_option?(issuable, project)
    if issuable.persisted?
      issuable.squash
    else
      project.squash_enabled_by_default?
    end
  end

  def state_name_with_icon(issuable)
    if issuable.is_a?(MergeRequest)
      if issuable.open?
        [_("Open"), "merge-request-open"]
      elsif issuable.merged?
        [_("Merged"), "merge"]
      else
        [_("Closed"), "merge-request-close"]
      end
    elsif issuable.open?
      [_("Open"), "issues"]
    else
      [_("Closed"), "issue-closed"]
    end
  end

  def hidden_issuable_icon(issuable)
    title = format(
      _('This %{issuable} is hidden because its author has been banned'),
      issuable: issuable.is_a?(Issue) ? _('issue') : _('merge request')
    )
    content_tag(:span, class: 'has-tooltip', title: title) do
      sprite_icon('spam', css_class: 'gl-vertical-align-text-bottom')
    end
  end

  def issuable_type_selector_data(issuable)
    {
      selected_type: issuable.issue_type,
      is_issue_allowed: create_issue_type_allowed?(@project, :issue).to_s,
      is_incident_allowed: create_issue_type_allowed?(@project, :incident).to_s,
      issue_path: new_project_issue_path(@project),
      incident_path: new_project_issue_path(@project, { issuable_template: 'incident', issue: { issue_type: 'incident' } })
    }
  end

  def issuable_label_selector_data(project, issuable)
    initial_labels = issuable.labels.map do |label|
      {
        __typename: "Label",
        id: label.id,
        title: label.title,
        description: label.description,
        color: label.color,
        text_color: label.text_color
      }
    end

    filter_base_path =
      if issuable.issuable_type == "merge_request"
        project_merge_requests_path(project)
      else
        project_issues_path(project)
      end

    {
      field_name: "#{issuable.class.model_name.param_key}[label_ids][]",
      full_path: project.full_path,
      initial_labels: initial_labels.to_json,
      issuable_type: issuable.issuable_type,
      labels_filter_base_path: filter_base_path,
      labels_manage_path: project_labels_path(project)
    }
  end

  private

  def sidebar_gutter_collapsed?
    cookies[:collapsed_gutter] == 'true'
  end

  def issuable_todo_button_data(issuable, is_collapsed)
    {
      todo_text: _('Add a to do'),
      mark_text: _('Mark as done'),
      todo_icon: sprite_icon('todo-add'),
      mark_icon: sprite_icon('todo-done', css_class: 'todo-undone'),
      issuable_id: issuable[:id],
      issuable_type: issuable[:type],
      create_path: issuable[:create_todo_path],
      delete_path: issuable.dig(:current_user, :todo, :delete_path),
      placement: is_collapsed ? 'left' : nil,
      container: is_collapsed ? 'body' : nil,
      boundary: 'viewport',
      is_collapsed: is_collapsed,
      track_label: "right_sidebar",
      track_property: "update_todo",
      track_action: "click_button",
      track_value: ""
    }
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

  def issuable_sidebar_options(issuable)
    {
      endpoint: "#{issuable[:issuable_json_path]}?serializer=sidebar_extras",
      toggleSubscriptionEndpoint: issuable[:toggle_subscription_path],
      moveIssueEndpoint: issuable[:move_issue_path],
      projectsAutocompleteEndpoint: issuable[:projects_autocomplete_path],
      editable: issuable.dig(:current_user, :can_edit).to_s,
      currentUser: issuable[:current_user],
      rootPath: root_path,
      fullPath: issuable[:project_full_path],
      iid: issuable[:iid],
      id: issuable[:id],
      severity: issuable[:severity],
      timeTrackingLimitToHours: Gitlab::CurrentSettings.time_tracking_limit_to_hours,
      canCreateTimelogs: issuable.dig(:current_user, :can_create_timelogs),
      createNoteEmail: issuable[:create_note_email],
      issuableType: issuable[:type]
    }
  end

  def sidebar_labels_data(issuable_sidebar, project)
    {
      allow_label_create: issuable_sidebar.dig(:current_user, :can_admin_label).to_s,
      allow_scoped_labels: issuable_sidebar[:scoped_labels_available].to_s,
      can_edit: issuable_sidebar.dig(:current_user, :can_edit).to_s,
      iid: issuable_sidebar[:iid],
      issuable_type: issuable_sidebar[:type],
      labels_fetch_path: issuable_sidebar[:project_labels_path],
      labels_manage_path: project_labels_path(project),
      project_issues_path: issuable_sidebar[:project_issuables_path],
      project_path: project.full_path,
      selected_labels: issuable_sidebar[:labels].to_json
    }
  end

  def sidebar_status_data(issuable_sidebar, project)
    {
      iid: issuable_sidebar[:iid],
      issuable_type: issuable_sidebar[:type],
      full_path: project.full_path,
      can_edit: issuable_sidebar.dig(:current_user, :can_edit).to_s
    }
  end

  def parent
    @project || @group
  end

  def format_count(issuable_type, count, threshold)
    if issuable_type == :issues && parent.is_a?(Group)
      format_cached_count(threshold, count)
    else
      number_with_delimiter(count)
    end
  end
end

IssuablesHelper.prepend_mod_with('IssuablesHelper')

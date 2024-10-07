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
      html << " " << gl_badge_tag(format_count(issuable_type, count, Gitlab::IssuablesCountForState::THRESHOLD), { variant: :muted }, { class: "gl-tab-counter-badge gl-hidden sm:gl-inline-flex" })
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
      imported: issuable.imported?,
      markdownPreviewPath: preview_markdown_path(parent, target_type: issuable.model_name, target_id: issuable.iid),
      markdownDocsPath: help_page_path('user/markdown.md'),
      lockVersion: issuable.lock_version,
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

  def has_filter_bar_param?
    finder.class.scalar_params.any? { |p| params[p].present? }
  end

  def issuable_squash_option?(issuable, project)
    if issuable.persisted?
      issuable.squash
    else
      project.squash_enabled_by_default?
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
        text_color: label.text_color,
        lock_on_merge: label.lock_on_merge
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
      labels_manage_path: project_labels_path(project),
      supports_lock_on_merge: issuable.supports_lock_on_merge?.to_s
    }
  end

  private

  def sidebar_gutter_collapsed?
    cookies[:collapsed_gutter] == 'true'
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

  def issuable_sidebar_options(issuable, project)
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
      issuableType: issuable[:type],
      directlyInviteMembers: can_admin_project_member?(project).to_s
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

  def issue_only_initial_data(issuable)
    return {} unless issuable.is_a?(Issue)

    {
      canCreateIncident: create_issue_type_allowed?(issuable.project, :incident),
      fullPath: issuable.project.full_path,
      iid: issuable.iid,
      issuableId: issuable.id,
      issueType: issuable.issue_type,
      isHidden: issue_hidden?(issuable),
      zoomMeetingUrl: ZoomMeeting.canonical_meeting_url(issuable),
      **incident_only_initial_data(issuable),
      **issue_header_data(issuable),
      **work_items_data
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

  def issue_header_data(issuable)
    data = {
      authorId: issuable.author.id,
      authorName: issuable.author.name,
      authorUsername: issuable.author.username,
      authorWebUrl: url_for(user_path(issuable.author)),
      createdAt: issuable.created_at.to_time.iso8601,
      isFirstContribution: issuable.first_contribution?,
      serviceDeskReplyTo: issuable.present(current_user: current_user).service_desk_reply_to
    }

    data.tap do |d|
      if issuable.duplicated? && can?(current_user, :read_issue, issuable.duplicated_to)
        d[:duplicatedToIssueUrl] = url_for([issuable.duplicated_to.project, issuable.duplicated_to, { only_path: false }])
      end

      if issuable.moved? && can?(current_user, :read_issue, issuable.moved_to)
        d[:movedToIssueUrl] = url_for([issuable.moved_to.project, issuable.moved_to, { only_path: false }])
      end
    end
  end

  def work_items_data
    {
      registerPath: new_user_registration_path(redirect_to_referer: 'yes'),
      signInPath: new_session_path(:user, redirect_to_referer: 'yes')
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

  def new_comment_template_paths(group, project = nil)
    [{
      text: _('Your comment templates'),
      href: profile_comment_templates_path
    }]
  end
end

IssuablesHelper.prepend_mod_with('IssuablesHelper')

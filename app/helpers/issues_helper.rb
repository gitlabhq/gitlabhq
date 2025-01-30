# frozen_string_literal: true

module IssuesHelper
  include Issues::IssueTypeHelpers

  def can_admin_issue?
    can?(current_user, :admin_issue, @group || @project)
  end

  def show_timeline_view_toggle?(issue)
    # Overridden in EE
    false
  end

  def issue_repositioning_disabled?
    if @group
      @group.root_ancestor.issue_repositioning_disabled?
    elsif @project
      @project.root_namespace.issue_repositioning_disabled?
    end
  end

  def confidential_icon(issue)
    sprite_icon('eye-slash', css_class: 'gl-align-text-bottom') if issue.confidential?
  end

  def issue_hidden?(issue)
    issue.hidden?
  end

  def award_user_list(awards, current_user, limit: 10)
    names = awards.map do |award|
      award.user == current_user ? 'You' : award.user.name
    end

    current_user_name = names.delete('You')
    names = names.insert(0, current_user_name).compact.first(limit)

    names << "#{awards.size - names.size} more." if awards.size > names.size

    names.to_sentence
  end

  def award_state_class(awardable, awards, current_user)
    if !can?(current_user, :award_emoji, awardable)
      "disabled"
    elsif current_user && awards.find { |a| a.user_id == current_user.id }
      "selected"
    else
      ""
    end
  end

  def awards_sort(awards)
    awards.sort_by do |award, award_emojis|
      case award
      when AwardEmoji::THUMBS_UP
        0
      when AwardEmoji::THUMBS_DOWN
        1
      else
        2
      end
    end.to_h
  end

  def link_to_discussions_to_resolve(merge_request, single_discussion = nil)
    link_text = [merge_request.to_reference]
    link_text << "(discussion #{single_discussion.first_note.id})" if single_discussion

    path = if single_discussion
             Gitlab::UrlBuilder.build(single_discussion.first_note)
           else
             project = merge_request.project
             project_merge_request_path(project, merge_request)
           end

    link_to link_text.join(' '), path
  end

  def show_new_issue_link?(project)
    return false unless project
    return false if project.archived?

    # We want to show the link to users that are not signed in, that way they
    # get directed to the sign-in/sign-up flow and afterwards to the new issue page.
    return true unless current_user

    can?(current_user, :create_issue, project)
  end

  def show_new_branch_button?
    can_create_confidential_merge_request? || !@issue.confidential?
  end

  def can_create_confidential_merge_request?
    @issue.confidential? && !@project.private? &&
      can?(current_user, :create_merge_request_in, @project)
  end

  def show_moved_service_desk_issue_warning?(issue)
    return false unless issue.moved_from
    return false unless issue.from_service_desk?

    ::ServiceDesk.enabled?(issue.moved_from.project) &&
      !::ServiceDesk.enabled?(issue.project)
  end

  def issue_header_actions_data(project, issuable, current_user, issuable_sidebar)
    new_issuable_params = { issue: {}, add_related_issue: issuable.iid }
    if issuable.work_item_type&.incident?
      new_issuable_params[:issuable_template] = 'incident'
      new_issuable_params[:issue][:issue_type] = 'incident'
    end

    {
      can_create_issue: show_new_issue_link?(project).to_s,
      can_create_incident: create_issue_type_allowed?(project, :incident).to_s,
      can_destroy_issue: can?(current_user, :"destroy_#{issuable.to_ability_name}", issuable).to_s,
      can_reopen_issue: can?(current_user, :reopen_issue, issuable).to_s,
      can_report_spam: issuable.submittable_as_spam_by?(current_user).to_s,
      can_update_issue: can?(current_user, :update_issue, issuable).to_s,
      is_issue_author: (issuable.author == current_user).to_s,
      issue_path: issuable_path(issuable),
      new_issue_path: new_project_issue_path(project, new_issuable_params),
      project_path: project.full_path,
      report_abuse_path: add_category_abuse_reports_path,
      reported_user_id: issuable.author.id,
      reported_from_url: issue_url(issuable),
      submit_as_spam_path: mark_as_spam_project_issue_path(project, issuable),
      issuable_email_address: issuable_sidebar.nil? ? '' : issuable_sidebar[:create_note_email]
    }
  end

  def common_issues_list_data(namespace, current_user)
    {
      autocomplete_award_emojis_path: autocomplete_award_emojis_path,
      calendar_path: url_for(safe_params.merge(calendar_url_options)),
      full_path: namespace.full_path,
      has_issue_date_filter_feature: has_issue_date_filter_feature?(namespace, current_user).to_s,
      initial_sort: current_user&.user_preference&.issues_sort,
      is_issue_repositioning_disabled: issue_repositioning_disabled?.to_s,
      is_public_visibility_restricted:
        Gitlab::CurrentSettings.restricted_visibility_levels&.include?(Gitlab::VisibilityLevel::PUBLIC).to_s,
      is_signed_in: current_user.present?.to_s,
      rss_path: url_for(safe_params.merge(rss_url_options)),
      sign_in_path: new_user_session_path,
      wi: work_items_show_data(namespace, current_user)
    }
  end

  def has_issue_date_filter_feature?(namespace, current_user)
    enabled_for_user = Feature.enabled?(:issue_date_filter, current_user)
    return true if enabled_for_user

    enabled_for_group = Feature.enabled?(:issue_date_filter, namespace.group) if namespace.respond_to?(:group)
    return true if enabled_for_group

    Feature.enabled?(:issue_date_filter, namespace)
  end

  def project_issues_list_data(project, current_user)
    common_issues_list_data(project, current_user).merge(
      can_bulk_update: can?(current_user, :admin_issue, project).to_s,
      can_create_issue: can?(current_user, :create_issue, project).to_s,
      can_edit: can?(current_user, :admin_project, project).to_s,
      can_import_issues: can?(current_user, :import_issues, @project).to_s,
      can_read_crm_contact: can?(current_user, :read_crm_contact, project.group).to_s,
      can_read_crm_organization: can?(current_user, :read_crm_organization, project.group).to_s,
      email: current_user&.notification_email_or_default,
      emails_help_page_path: help_page_path('development/emails.md', anchor: 'email-namespace'),
      export_csv_path: export_csv_project_issues_path(project),
      has_any_issues: project_issues(project).exists?.to_s,
      import_csv_issues_path: import_csv_namespace_project_issues_path,
      initial_email: project.new_issuable_address(current_user, 'issue'),
      is_project: true.to_s,
      markdown_help_path: help_page_path('user/markdown.md'),
      max_attachment_size: number_to_human_size(Gitlab::CurrentSettings.max_attachment_size.megabytes),
      new_issue_path: new_project_issue_path(project),
      project_import_jira_path: project_import_jira_path(project),
      quick_actions_help_path: help_page_path('user/project/quick_actions.md'),
      releases_path: project_releases_path(project, format: :json),
      reset_path: new_issuable_address_project_path(project, issuable_type: 'issue'),
      show_new_issue_link: show_new_issue_link?(project).to_s
    )
  end

  def group_issues_list_data(group, current_user)
    common_issues_list_data(group, current_user).merge(
      can_create_projects: can?(current_user, :create_projects, group).to_s,
      can_read_crm_contact: can?(current_user, :read_crm_contact, group).to_s,
      can_read_crm_organization: can?(current_user, :read_crm_organization, group).to_s,
      group_id: group.id,
      has_any_issues: @has_issues.to_s,
      has_any_projects: @has_projects.to_s,
      new_project_path: new_project_path(namespace_id: group.id)
    )
  end

  def dashboard_issues_list_data(current_user)
    {
      autocomplete_award_emojis_path: autocomplete_award_emojis_path,
      autocomplete_users_path: autocomplete_users_path,
      calendar_path: url_for(safe_params.merge(calendar_url_options)),
      dashboard_labels_path: dashboard_labels_path(format: :json, include_ancestor_groups: true),
      dashboard_milestones_path: dashboard_milestones_path(format: :json),
      empty_state_with_filter_svg_path: image_path('illustrations/empty-state/empty-issues-md.svg'),
      empty_state_without_filter_svg_path: image_path('illustrations/empty-state/empty-search-md.svg'),
      has_issue_date_filter_feature: Feature.enabled?(:issue_date_filter, current_user).to_s,
      initial_sort: current_user&.user_preference&.issues_sort,
      is_public_visibility_restricted:
        Gitlab::CurrentSettings.restricted_visibility_levels&.include?(Gitlab::VisibilityLevel::PUBLIC).to_s,
      is_signed_in: current_user.present?.to_s,
      rss_path: url_for(safe_params.merge(rss_url_options))
    }
  end

  def issues_form_data(project)
    {
      new_issue_path: new_project_issue_path(project)
    }
  end

  # Overridden in EE
  def scoped_labels_available?(parent)
    false
  end

  def award_emoji_issue_api_path(issue)
    api_v4_projects_issues_award_emoji_path(id: issue.project.id, issue_iid: issue.iid)
  end
end

IssuesHelper.prepend_mod_with('IssuesHelper')

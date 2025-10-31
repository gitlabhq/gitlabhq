# frozen_string_literal: true

module WorkItemsHelper
  include IssuesHelper

  # overridden in EE
  def work_items_data(resource_parent, current_user)
    group = extract_group(resource_parent)

    base_data(resource_parent, current_user, group).tap do |data|
      add_project_specific_data(data, resource_parent, current_user)
    end
  end

  # Minimal data for GraphQL-enabled views, returns only server-provided properties not yet migrated to GraphQL.
  # This method will be removed once all properties are migrated to GraphQL.
  # overridden in EE
  def work_item_views_only_data(resource_parent, current_user)
    group = extract_group(resource_parent)

    base_data_legacy_only(resource_parent, current_user, group).tap do |data|
      add_project_specific_data(data, resource_parent, current_user)
    end
  end

  # overridden in EE
  def add_work_item_show_breadcrumb(resource_parent, _iid)
    path = resource_parent.is_a?(Group) ? issues_group_path(resource_parent) : project_issues_path(resource_parent)

    add_to_breadcrumbs(_('Issues'), path)
  end

  # overridden in EE
  def instance_type_new_trial_path(_group)
    self_managed_new_trial_url
  end

  private

  def add_project_specific_data(data, resource_parent, current_user)
    return unless resource_parent.is_a?(Project)

    data[:releases_path] = project_releases_path(resource_parent, format: :json)
    data[:project_import_jira_path] = project_import_jira_path(resource_parent)
    data[:can_import_work_items] = can?(current_user, :import_work_items, resource_parent).to_s
    data[:export_csv_path] = export_csv_project_issues_path(resource_parent)
    data[:new_issue_path] = new_project_issue_path(resource_parent)
  end

  def extract_group(resource_parent)
    resource_parent.is_a?(Group) ? resource_parent : resource_parent.group
  end

  def base_data(resource_parent, current_user, group)
    {
      autocomplete_award_emojis_path: autocomplete_award_emojis_path,
      can_admin_label: can?(current_user, :admin_label, resource_parent).to_s,
      can_bulk_update: can?(current_user, :admin_issue, resource_parent).to_s,
      can_edit: can?(current_user, :admin_project, resource_parent).to_s,
      full_path: resource_parent.full_path,
      group_path: group&.full_path,
      issues_list_path: issues_path_for(resource_parent),
      labels_manage_path: labels_path_for(resource_parent),
      register_path: new_user_registration_path(redirect_to_referer: 'yes'),
      sign_in_path: new_session_path(:user, redirect_to_referer: 'yes'),
      new_trial_path: instance_type_new_trial_path(group),
      new_comment_template_paths: new_comment_template_paths(group).to_json,
      report_abuse_path: add_category_abuse_reports_path,
      default_branch: resource_parent.is_a?(Project) ? resource_parent.default_branch_or_main : nil,
      initial_sort: current_user&.user_preference&.issues_sort,
      is_signed_in: current_user.present?.to_s,
      show_new_work_item: show_new_work_item_link?(resource_parent).to_s,
      is_issue_repositioning_disabled: issue_repositioning_disabled(resource_parent).to_s,
      can_create_projects: can?(current_user, :create_projects, group).to_s,
      new_project_path: new_project_path(namespace_id: group&.id),
      project_namespace_full_path:
        resource_parent.is_a?(Project) ? resource_parent.namespace.full_path : resource_parent.full_path,
      group_id: group&.id,
      time_tracking_limit_to_hours: Gitlab::CurrentSettings.time_tracking_limit_to_hours.to_s,
      can_read_crm_contact: can?(current_user, :read_crm_contact, resource_parent.crm_group).to_s,
      max_attachment_size: number_to_human_size(Gitlab::CurrentSettings.max_attachment_size.megabytes),
      can_read_crm_organization: can?(current_user, :read_crm_organization, resource_parent.crm_group).to_s,
      rss_path: rss_path_for(resource_parent),
      calendar_path: calendar_path_for(resource_parent),
      has_projects: has_group_projects?(resource_parent).to_s,
      work_item_planning_view_enabled: resource_parent.work_items_consolidated_list_enabled?.to_s
    }
  end

  def base_data_legacy_only(resource_parent, current_user, group)
    {
      autocomplete_award_emojis_path: autocomplete_award_emojis_path,
      can_bulk_update: can?(current_user, :admin_issue, resource_parent).to_s,
      can_edit: can?(current_user, :admin_project, resource_parent).to_s,
      full_path: resource_parent.full_path,
      group_path: group&.full_path,
      issues_list_path: issues_path_for(resource_parent),
      new_trial_path: instance_type_new_trial_path(group),
      default_branch: resource_parent.is_a?(Project) ? resource_parent.default_branch_or_main : nil,
      initial_sort: current_user&.user_preference&.issues_sort,
      is_signed_in: current_user.present?.to_s,
      show_new_work_item: show_new_work_item_link?(resource_parent).to_s,
      is_issue_repositioning_disabled: issue_repositioning_disabled(resource_parent).to_s,
      project_namespace_full_path:
        resource_parent.is_a?(Project) ? resource_parent.namespace.full_path : resource_parent.full_path,
      group_id: group&.id,
      time_tracking_limit_to_hours: Gitlab::CurrentSettings.time_tracking_limit_to_hours.to_s,
      can_read_crm_contact: can?(current_user, :read_crm_contact, resource_parent.crm_group).to_s,
      max_attachment_size: number_to_human_size(Gitlab::CurrentSettings.max_attachment_size.megabytes),
      can_read_crm_organization: can?(current_user, :read_crm_organization, resource_parent.crm_group).to_s,
      rss_path: rss_path_for(resource_parent),
      calendar_path: calendar_path_for(resource_parent),
      has_projects: has_group_projects?(resource_parent).to_s
    }
  end

  def issues_path_for(resource_parent)
    resource_parent.is_a?(Group) ? issues_group_path(resource_parent) : project_issues_path(resource_parent)
  end

  def labels_path_for(resource_parent)
    resource_parent.is_a?(Group) ? group_labels_path(resource_parent) : project_labels_path(resource_parent)
  end

  def rss_path_for(resource_parent)
    params = safe_params.merge(rss_url_options)

    if resource_parent.is_a?(Group)
      # Remove id and use group_id instead for the route
      params = params.except(:id)
      url_for(params.merge(controller: 'groups/work_items', action: 'index', group_id: resource_parent.to_param))
    else
      url_for(params.merge(controller: 'projects/work_items',
        action: 'rss',
        namespace_id: resource_parent.namespace.to_param,
        project_id: resource_parent.to_param))
    end
  end

  def calendar_path_for(resource_parent)
    params = safe_params.merge(calendar_url_options)

    if resource_parent.is_a?(Group)
      # Remove id and use group_id instead for the route
      params = params.except(:id)
      url_for(params.merge(controller: 'groups/work_items', action: 'index', group_id: resource_parent.to_param))
    else
      url_for(params.merge(controller: 'projects/work_items',
        action: 'calendar',
        namespace_id: resource_parent.namespace.to_param,
        project_id: resource_parent.to_param))
    end
  end

  def show_new_work_item_link?(resource_parent)
    return false unless resource_parent
    return false if resource_parent.self_or_ancestors_archived?

    # We want to show the link to users that are not signed in, that way they
    # get directed to the sign-in/sign-up flow and afterwards to the new issue page.
    # Note that we do this only for the project issues page
    return true if !resource_parent.is_a?(Group) && !current_user

    can?(current_user, :create_work_item, resource_parent)
  end

  def issue_repositioning_disabled(resource_parent)
    if resource_parent.is_a?(Group)
      resource_parent.root_ancestor.issue_repositioning_disabled?
    elsif resource_parent.is_a?(Project)
      resource_parent.root_namespace.issue_repositioning_disabled?
    end
  end

  def has_group_projects?(group)
    return false unless group.is_a?(Group)

    GroupProjectsFinder.new(group: group, current_user: current_user).execute.exists?
  end
end

# frozen_string_literal: true

module SidebarsHelper
  include MergeRequestsHelper
  include Nav::NewDropdownHelper

  def organization_sidebar_context(organization, user, **args)
    Sidebars::Context.new(container: organization, current_user: user, **args)
  end

  def project_sidebar_context(project, user, current_ref, ref_type: nil, **args)
    context_data = project_sidebar_context_data(project, user, current_ref, ref_type: ref_type)
    Sidebars::Projects::Context.new(**context_data, **args)
  end

  def group_sidebar_context(group, user, **args)
    context_data = group_sidebar_context_data(group, user)

    Sidebars::Groups::Context.new(**context_data, **args)
  end

  def your_work_sidebar_context(user, **args)
    context_data = your_work_context_data(user)

    Sidebars::Context.new(**context_data, **args)
  end

  def super_sidebar_context(user, group:, project:, panel:, panel_type:)
    return super_sidebar_logged_out_context(panel: panel, panel_type: panel_type) unless user

    super_sidebar_logged_in_context(user, group: group, project: project, panel: panel, panel_type: panel_type)
  end

  def super_sidebar_shared_context(panel:, panel_type:)
    super_sidebar_instance_version_data.merge(super_sidebar_whats_new_data).merge({
      is_logged_in: false,
      compare_plans_url: compare_plans_url,
      context_switcher_links: context_switcher_links,
      current_menu_items: panel.super_sidebar_menu_items,
      current_context_header: panel.super_sidebar_context_header,
      support_path: support_url,
      docs_path: help_docs_path,
      display_whats_new: display_whats_new?,
      show_version_check: show_version_check?,
      search: search_data,
      panel_type: panel_type,
      shortcut_links: shortcut_links,
      terms: terms_link
    })
  end

  def super_sidebar_logged_out_context(panel:, panel_type:)
    sidebar_context = super_sidebar_shared_context(panel: panel, panel_type: panel_type)

    return sidebar_context unless Users::ProjectStudio.new(current_user).enabled?

    sidebar_context.merge({
      sign_in_visible: header_link?(:sign_in).to_s,
      allow_signup: allow_signup?.to_s,
      new_user_registration_path: new_user_registration_path,
      sign_in_path: new_session_path(:user, redirect_to_referer: 'yes')
    })
  end

  def super_sidebar_logged_in_context(user, group:, project:, panel:, panel_type:)
    super_sidebar_shared_context(panel: panel, panel_type: panel_type).merge({
      is_logged_in: true,
      is_admin: user.can_admin_all_resources?,
      name: user.name,
      username: user.username,
      admin_url: admin_root_path,
      admin_mode: {
        admin_mode_feature_enabled: Gitlab::CurrentSettings.admin_mode,
        admin_mode_active: current_user_mode.admin_mode?,
        enter_admin_mode_url: new_admin_session_path,
        leave_admin_mode_url: destroy_admin_session_path,
        user_is_admin: user.can_access_admin_area?
      },
      avatar_url: user.avatar_url,
      has_link_to_profile: current_user_menu?(:profile),
      link_to_profile: user_path(user),
      logo_url: current_appearance&.header_logo_path,
      status: user_status_menu_data(user),
      settings: {
        has_settings: current_user_menu?(:settings),
        profile_path: user_settings_profile_path,
        profile_preferences_path: profile_preferences_path
      },
      user_counts: {
        assigned_issues: user.assigned_open_issues_count,
        assigned_merge_requests: user.all_assigned_merge_requests_count(cached_only: true),
        review_requested_merge_requests: user.review_requested_open_merge_requests_count(cached_only: true),
        todos: user.todos_pending_count,
        last_update: time_in_milliseconds
      },
      can_sign_out: current_user_menu?(:sign_out),
      sign_out_link: destroy_user_session_path,
      issues_dashboard_path: issues_dashboard_path(assignee_username: user.username),
      merge_request_dashboard_path: merge_requests_dashboard_path,
      todos_dashboard_path: dashboard_todos_path,
      compare_plans_url: compare_plans_url(user: user, project: project, group: group),
      create_new_menu_groups: create_new_menu_groups(group: group, project: project),
      projects_path: dashboard_projects_path,
      groups_path: dashboard_groups_path,
      gitlab_com_but_not_canary: Gitlab.com_but_not_canary?,
      gitlab_com_and_canary: Gitlab.com_and_canary?,
      canary_toggle_com_url: Gitlab::Saas.canary_toggle_com_url,
      current_context: super_sidebar_current_context(project: project, group: group),
      pinned_items: pinned_items(user, panel_type, group: group),
      update_pins_url: pins_path,
      is_impersonating: impersonating?,
      stop_impersonation_path: admin_impersonation_path,
      shortcut_links: shortcut_links(user: user, project: project),
      track_visits_path: track_namespace_visits_path,
      work_items: work_items_modal_data(group, project)
    })
  end

  def super_sidebar_instance_version_data
    return {} unless show_version_check?

    {
      gitlab_version: Gitlab.version_info,
      gitlab_version_check: gitlab_version_check
    }
  end

  def super_sidebar_whats_new_data
    return {} unless display_whats_new?

    {
      whats_new_most_recent_release_items_count: whats_new_most_recent_release_items_count,
      whats_new_version_digest: whats_new_version_digest,
      whats_new_read_articles: whats_new_read_articles,
      whats_new_mark_as_read_path: whats_new_mark_as_read_path
    }
  end

  def work_items_modal_data(group, project)
    if project&.persisted?
      return {
        full_path: project.full_path,
        has_issuable_health_status_feature: project.licensed_feature_available?(:issuable_health_status).to_s,
        issues_list_path: project_issues_path(project),
        labels_manage_path: project_labels_path(project),
        can_admin_label: can?(current_user, :admin_label, project).to_s,
        has_issue_weights_feature: project.licensed_feature_available?(:issue_weights).to_s,
        has_iterations_feature: project.licensed_feature_available?(:iterations).to_s,
        work_item_planning_view_enabled: project.work_items_consolidated_list_enabled?.to_s
      }
    end

    return unless group && group.id

    {
      full_path: group.full_path,
      has_issuable_health_status_feature: group.licensed_feature_available?(:issuable_health_status).to_s,
      issues_list_path: issues_group_path(group),
      labels_manage_path: group_labels_path(group),
      can_admin_label: can?(current_user, :admin_label, group).to_s,
      has_issue_weights_feature: group.licensed_feature_available?(:issue_weights).to_s,
      work_item_planning_view_enabled: group.work_items_consolidated_list_enabled?.to_s
    }
  end

  def super_sidebar_nav_panel(
    nav: nil, project: nil, user: nil, group: nil, current_ref: nil, ref_type: nil,
    viewed_user: nil, organization: nil)
    context_adds = { route_is_active: method(:active_nav_link?), is_super_sidebar: true }
    panel = case nav
            when 'project'
              context = project_sidebar_context(project, user, current_ref, ref_type: ref_type, **context_adds)
              Sidebars::Projects::SuperSidebarPanel.new(context)
            when 'group'
              context = group_sidebar_context(group, user, **context_adds)
              Sidebars::Groups::SuperSidebarPanel.new(context)
            when 'profile'
              context = Sidebars::Context.new(current_user: user, container: user, **context_adds)
              Sidebars::UserSettings::Panel.new(context)
            when 'user_profile'
              context = Sidebars::Context.new(current_user: user, container: viewed_user, **context_adds)
              Sidebars::UserProfile::Panel.new(context)
            when 'explore'
              Sidebars::Explore::Panel.new(
                Sidebars::Context.new(
                  current_user: user,
                  container: nil,
                  current_organization: Current.organization,
                  **context_adds
                )
              )
            when 'search'
              context = Sidebars::Context.new(current_user: user, container: nil, **context_adds)
              Sidebars::Search::Panel.new(context)
            when 'admin'
              Sidebars::Admin::Panel.new(Sidebars::Context.new(current_user: user, container: nil, **context_adds))
            when 'organization'
              context = organization_sidebar_context(organization, user, **context_adds)
              Sidebars::Organizations::SuperSidebarPanel.new(context)
            when 'your_work'
              context = your_work_sidebar_context(user, **context_adds)
              Sidebars::YourWork::Panel.new(context)
            end

    # We only return the panel if any menu item is rendered, otherwise fallback
    return panel if panel&.render?

    fallback_sidebar_panel(nav, context_adds, user)
  end

  def command_palette_data(project: nil, current_ref: nil)
    return {} unless project&.repo_exists?
    return {} if project.empty_repo?

    {
      project_files_url: project_files_path(project, current_ref || project.default_branch, format: :json),
      project_blob_url: project_blob_path(project, current_ref || project.default_branch)
    }
  end

  def compare_plans_url(*)
    "#{promo_url}/pricing"
  end

  private

  def fallback_sidebar_panel(nav, context_adds, user = nil)
    # Fallback when panels fail to render:
    # - UserProfile panel failures (no accessible content) -> Explore navigation for private/blocked users
    # - Other panel failures -> Your Work (logged-in) or Explore (anonymous)
    if nav != 'user_profile' && user
      context = your_work_sidebar_context(user, **context_adds)
      return Sidebars::YourWork::Panel.new(context)
    end

    Sidebars::Explore::Panel.new(
      Sidebars::Context.new(
        current_user: user,
        container: nil,
        current_organization: Current.organization,
        **context_adds
      )
    )
  end

  def search_data
    {
      search_path: search_path,
      issues_path: issues_dashboard_path,
      mr_path: merge_requests_dashboard_path,
      autocomplete_path: search_autocomplete_path,
      settings_path: search_settings_path,
      search_context: header_search_context
    }
  end

  def user_status_menu_data(user)
    {
      can_update: can?(user, :update_user_status, user),
      busy: user.status&.busy?,
      customized: user.status&.customized?,
      availability: user.status&.availability.to_s,
      emoji: user.status&.emoji,
      message_html: user.status&.message_html&.html_safe,
      message: user.status&.message,
      clear_after: user_clear_status_at(user)
    }
  end

  def create_new_menu_groups(group:, project:)
    new_dropdown_sections = new_dropdown_view_model(group: group, project: project)[:menu_sections]
    show_headers = new_dropdown_sections.length > 1
    new_dropdown_sections.map do |section|
      {
        name: show_headers ? section[:title] : '',
        items: section[:menu_items].map do |item|
                 {
                   text: item[:title],
                   href: item[:href].presence,
                   component: item[:component].presence,
                   extraAttrs: {
                     'data-track-label': item[:id],
                     'data-track-action': 'click_link',
                     'data-track-property': 'nav_create_menu',
                     'data-testid': 'create_menu_item',
                     'data-qa-create-menu-item': item[:id]
                   }
                 }
               end
      }
    end
  end

  def project_sidebar_context_data(project, user, current_ref, ref_type: nil)
    {
      current_user: user,
      container: project,
      current_ref: current_ref,
      ref_type: ref_type,
      jira_issues_integration: project_jira_issues_integration?,
      can_view_pipeline_editor: can_view_pipeline_editor?(project),
      show_cluster_hint: show_gke_cluster_integration_callout?(project)
    }
  end

  def group_sidebar_context_data(group, user)
    {
      current_user: user,
      container: group
    }
  end

  def your_work_context_data(user)
    {
      current_user: user,
      container: user,
      show_security_dashboard: false
    }
  end

  def super_sidebar_current_context(project: nil, group: nil)
    if project&.persisted?
      return {
        namespace: 'projects',
        item: {
          id: project.id,
          name: project.name,
          namespace: project.full_name,
          fullPath: project.full_path,
          webUrl: project_path(project),
          avatarUrl: project.avatar_url
        }
      }
    end

    if group&.persisted?
      return {
        namespace: 'groups',
        item: {
          id: group.id,
          name: group.name,
          namespace: group.full_name,
          fullPath: group.full_path,
          webUrl: group_path(group),
          avatarUrl: group.avatar_url
        }
      }
    end

    {}
  end

  def context_switcher_links
    links = [
      ({ title: s_('Navigation|Your work'), link: root_path, icon: 'work' } if current_user),
      { title: s_('Navigation|Explore'), link: explore_root_path, icon: 'compass' },
      ({ title: s_('Navigation|Profile'), link: user_settings_profile_path, icon: 'profile' } if current_user),
      ({ title: s_('Navigation|Preferences'), link: profile_preferences_path, icon: 'preferences' } if current_user)
    ]

    if display_admin_area_link?
      links.append(
        { title: s_('Navigation|Admin area'), link: admin_area_link, icon: 'admin' }
      )
    end

    links.compact
  end

  def impersonating?
    !!session[:impersonator_id]
  end

  def shortcut_links_anonymous
    [
      {
        title: _('Snippets'),
        href: explore_snippets_path,
        css_class: 'dashboard-shortcuts-snippets'
      },
      {
        title: _('Groups'),
        href: explore_groups_path,
        css_class: 'dashboard-shortcuts-groups'
      },
      {
        title: _('Projects'),
        href: starred_explore_projects_path,
        css_class: 'dashboard-shortcuts-projects'
      }
    ]
  end

  def shortcut_links(user: nil, project: nil)
    return shortcut_links_anonymous unless user

    shortcut_links = [
      {
        title: _('Milestones'),
        href: dashboard_milestones_path,
        css_class: 'dashboard-shortcuts-milestones'
      },
      {
        title: _('Snippets'),
        href: dashboard_snippets_path,
        css_class: 'dashboard-shortcuts-snippets'
      },
      {
        title: _('Activity'),
        href: activity_dashboard_path,
        css_class: 'dashboard-shortcuts-activity'
      },
      {
        title: _('Groups'),
        href: dashboard_groups_path,
        css_class: 'dashboard-shortcuts-groups'
      },
      {
        title: _('Projects'),
        href: dashboard_projects_path,
        css_class: 'dashboard-shortcuts-projects'
      }
    ]

    if project&.persisted? && can?(user, :create_issue, project)
      shortcut_links << {
        title: _('Create a new issue'),
        href: new_project_issue_path(project),
        css_class: 'shortcuts-new-issue'
      }
    end

    shortcut_links
  end

  # overridden on EE
  # rubocop:disable Lint/UnusedMethodArgument -- group is used on EE
  def pinned_items(user, panel_type, group: nil)
    user.pinned_nav_items[panel_type]&.map(&:to_s) ||
      super_sidebar_default_pins(panel_type, user)
  end
  # rubocop:enable Lint/UnusedMethodArgument

  def super_sidebar_default_pins(panel_type, user)
    case panel_type
    when 'project'
      project_default_pins(user)
    when 'group'
      group_default_pins(user)
    else
      []
    end
  end

  def project_default_pins(_user)
    %w[project_issue_list project_merge_request_list]
  end

  def group_default_pins(_user)
    %w[group_issue_list group_merge_request_list]
  end

  def terms_link
    Gitlab::CurrentSettings.terms ? '/-/users/terms' : nil
  end

  def admin_area_link
    admin_root_path
  end

  def display_admin_area_link?
    current_user&.can?(:access_admin_area)
  end
end

SidebarsHelper.prepend_mod_with('SidebarsHelper')

# frozen_string_literal: true

module SidebarsHelper
  include MergeRequestsHelper
  include Nav::NewDropdownHelper

  def sidebar_tracking_attributes_by_object(object)
    sidebar_attributes_for_object(object).fetch(:tracking_attrs, {})
  end

  def sidebar_qa_selector(object)
    sidebar_attributes_for_object(object).fetch(:sidebar_qa_selector, nil)
  end

  def scope_qa_menu_item(object)
    sidebar_attributes_for_object(object).fetch(:scope_qa_menu_item, nil)
  end

  def scope_avatar_classes(object)
    %w[avatar-container rect-avatar s32].tap do |klasses|
      klass = sidebar_attributes_for_object(object).fetch(:scope_avatar_class, nil)
      klasses << klass if klass
    end
  end

  def project_sidebar_context(project, user, current_ref, ref_type: nil, **args)
    context_data = project_sidebar_context_data(project, user, current_ref, ref_type: ref_type)
    Sidebars::Projects::Context.new(**context_data, **args)
  end

  def group_sidebar_context(group, user, **args)
    context_data = group_sidebar_context_data(group, user)

    Sidebars::Groups::Context.new(**context_data, **args)
  end

  def super_sidebar_context(user, group:, project:, panel:)
    {
      current_menu_items: panel.super_sidebar_menu_items,
      current_context_header: panel.super_sidebar_context_header,
      name: user.name,
      username: user.username,
      avatar_url: user.avatar_url,
      has_link_to_profile: current_user_menu?(:profile),
      link_to_profile: user_url(user),
      status: {
        can_update: can?(current_user, :update_user_status, current_user),
        busy: user.status&.busy?,
        customized: user.status&.customized?,
        availability: user.status&.availability.to_s,
        emoji: user.status&.emoji,
        message: user.status&.message_html&.html_safe,
        clear_after: user.status&.clear_status_at.to_s
      },
      trial: {
        has_start_trial: current_user_menu?(:start_trial),
        url: trials_link_url
      },
      settings: {
        has_settings: current_user_menu?(:settings),
        profile_path: profile_path,
        profile_preferences_path: profile_preferences_path
      },
      can_sign_out: current_user_menu?(:sign_out),
      sign_out_link: destroy_user_session_path,
      assigned_open_issues_count: user.assigned_open_issues_count,
      todos_pending_count: user.todos_pending_count,
      issues_dashboard_path: issues_dashboard_path(assignee_username: user.username),
      total_merge_requests_count: user_merge_requests_counts[:total],
      create_new_menu_groups: create_new_menu_groups(group: group, project: project),
      merge_request_menu: create_merge_request_menu(user),
      support_path: support_url,
      display_whats_new: display_whats_new?,
      whats_new_most_recent_release_items_count: whats_new_most_recent_release_items_count,
      whats_new_version_digest: whats_new_version_digest,
      show_version_check: show_version_check?,
      gitlab_version: Gitlab.version_info,
      gitlab_version_check: gitlab_version_check,
      gitlab_com_but_not_canary: Gitlab.com_but_not_canary?,
      gitlab_com_and_canary: Gitlab.com_and_canary?,
      canary_toggle_com_url: Gitlab::Saas.canary_toggle_com_url
    }
  end

  def super_sidebar_nav_panel(nav: nil, project: nil, user: nil, group: nil, current_ref: nil, ref_type: nil)
    case nav
    when 'project'
      context = project_sidebar_context(project, user, current_ref, ref_type: ref_type,
        route_is_active: method(:active_nav_link?))
      Sidebars::Projects::SuperSidebarPanel.new(context)
    when 'group'
      context = group_sidebar_context(group, user, route_is_active: method(:active_nav_link?))
      Sidebars::Groups::Panel.new(context)
    else
      Sidebars::YourWork::Panel.new(Sidebars::Context.new(current_user: user, container: nil,
        route_is_active: method(:active_nav_link?)))
    end
  end

  private

  def create_new_menu_groups(group:, project:)
    new_dropdown_sections = new_dropdown_view_model(group: group, project: project)[:menu_sections]
    show_headers = new_dropdown_sections.length > 1
    new_dropdown_sections.map do |section|
      {
        name: show_headers ? section[:title] : '',
        items: section[:menu_items].map do |item|
          {
            text: item[:title],
            href: item[:href]
          }
        end
      }
    end
  end

  def create_merge_request_menu(user)
    [
      {
        name: _('Merge requests'),
        items: [
          {
            text: _('Assigned'),
            href: merge_requests_dashboard_path(assignee_username: user.username),
            count: user_merge_requests_counts[:assigned]
          },
          {
            text: _('Review requests'),
            href: merge_requests_dashboard_path(reviewer_username: user.username),
            count: user_merge_requests_counts[:review_requested]
          }
        ]
      }
    ]
  end

  def sidebar_attributes_for_object(object)
    case object
    when Project
      sidebar_project_attributes
    when Group
      sidebar_group_attributes
    when User
      sidebar_user_attributes
    else
      {}
    end
  end

  def sidebar_project_attributes
    {
      tracking_attrs: sidebar_project_tracking_attrs,
      sidebar_qa_selector: 'project_sidebar',
      scope_qa_menu_item: 'Project scope',
      scope_avatar_class: 'project_avatar'
    }
  end

  def sidebar_group_attributes
    {
      tracking_attrs: sidebar_group_tracking_attrs,
      sidebar_qa_selector: 'group_sidebar',
      scope_qa_menu_item: 'Group scope',
      scope_avatar_class: 'group_avatar'
    }
  end

  def sidebar_user_attributes
    {
      tracking_attrs: sidebar_user_profile_tracking_attrs
    }
  end

  def sidebar_project_tracking_attrs
    tracking_attrs('projects_side_navigation', 'render', 'projects_side_navigation')
  end

  def sidebar_group_tracking_attrs
    tracking_attrs('groups_side_navigation', 'render', 'groups_side_navigation')
  end

  def sidebar_user_profile_tracking_attrs
    tracking_attrs('user_side_navigation', 'render', 'user_side_navigation')
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
end

SidebarsHelper.prepend_mod_with('SidebarsHelper')

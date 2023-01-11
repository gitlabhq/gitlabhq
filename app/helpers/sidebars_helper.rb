# frozen_string_literal: true

module SidebarsHelper
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

  def project_sidebar_context(project, user, current_ref, ref_type: nil)
    context_data = project_sidebar_context_data(project, user, current_ref, ref_type: ref_type)
    Sidebars::Projects::Context.new(**context_data)
  end

  def group_sidebar_context(group, user)
    context_data = group_sidebar_context_data(group, user)

    Sidebars::Groups::Context.new(**context_data)
  end

  def super_sidebar_context(user)
    {
      name: user.name,
      username: user.username,
      avatar_url: user.avatar_url,
      assigned_open_issues_count: user.assigned_open_issues_count,
      assigned_open_merge_requests_count: user.assigned_open_merge_requests_count,
      todos_pending_count: user.todos_pending_count,
      issues_dashboard_path: issues_dashboard_path(assignee_username: user.username)
    }
  end

  private

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
      learn_gitlab_enabled: learn_gitlab_enabled?(project),
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

# frozen_string_literal: true

module SidebarsHelper
  def sidebar_tracking_attributes_by_object(object)
    case object
    when Project
      sidebar_project_tracking_attrs
    when Group
      sidebar_group_tracking_attrs
    when User
      sidebar_user_profile_tracking_attrs
    else
      {}
    end
  end

  def project_sidebar_context(project, user, current_ref)
    context_data = project_sidebar_context_data(project, user, current_ref)

    Sidebars::Projects::Context.new(**context_data)
  end

  private

  def sidebar_project_tracking_attrs
    tracking_attrs('projects_side_navigation', 'render', 'projects_side_navigation')
  end

  def sidebar_group_tracking_attrs
    tracking_attrs('groups_side_navigation', 'render', 'groups_side_navigation')
  end

  def sidebar_user_profile_tracking_attrs
    tracking_attrs('user_side_navigation', 'render', 'user_side_navigation')
  end

  def project_sidebar_context_data(project, user, current_ref)
    {
      current_user: user,
      container: project,
      learn_gitlab_experiment_enabled: learn_gitlab_experiment_enabled?(project),
      learn_gitlab_experiment_tracking_category: learn_gitlab_experiment_tracking_category,
      current_ref: current_ref,
      jira_issues_integration: project_jira_issues_integration?,
      can_view_pipeline_editor: can_view_pipeline_editor?(project),
      show_cluster_hint: show_gke_cluster_integration_callout?(project)
    }
  end
end

SidebarsHelper.prepend_mod_with('SidebarsHelper')

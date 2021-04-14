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

  def project_sidebar_context(project, user)
    Sidebars::Projects::Context.new(**project_sidebar_context_data(project, user))
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

  def project_sidebar_context_data(project, user)
    {
      current_user: user,
      container: project
    }
  end
end

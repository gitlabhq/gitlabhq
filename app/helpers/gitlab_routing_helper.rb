# Shorter routing method for project and project items
# Since update to rails 4.1.9 we are now allowed to use `/` in project routing
# so we use nested routing for project resources which include project and
# project namespace. To avoid writing long methods every time we define shortcuts for
# some of routing.
#
# For example instead of this:
#
#   namespace_project_merge_request_path(merge_request.project.namespace, merge_request.projects, merge_request)
#
# We can simply use shortcut:
#
#   merge_request_path(merge_request)
#
module GitlabRoutingHelper
  def project_path(project, *args)
    namespace_project_path(project.namespace, project, *args)
  end

  def project_files_path(project, *args)
    namespace_project_tree_path(project.namespace, project, @ref || project.repository.root_ref)
  end

  def project_commits_path(project, *args)
    namespace_project_commits_path(project.namespace, project, @ref || project.repository.root_ref)
  end

  def project_builds_path(project, *args)
    namespace_project_builds_path(project.namespace, project, *args)
  end

  def activity_project_path(project, *args)
    activity_namespace_project_path(project.namespace, project, *args)
  end

  def edit_project_path(project, *args)
    edit_namespace_project_path(project.namespace, project, *args)
  end

  def runners_path(project, *args)
    namespace_project_runners_path(project.namespace, project, *args)
  end

  def runner_path(runner, *args)
    namespace_project_runner_path(@project.namespace, @project, runner, *args)
  end

  def issue_path(entity, *args)
    namespace_project_issue_path(entity.project.namespace, entity.project, entity, *args)
  end

  def merge_request_path(entity, *args)
    namespace_project_merge_request_path(entity.project.namespace, entity.project, entity, *args)
  end

  def milestone_path(entity, *args)
    namespace_project_milestone_path(entity.project.namespace, entity.project, entity, *args)
  end

  def project_url(project, *args)
    namespace_project_url(project.namespace, project, *args)
  end

  def edit_project_url(project, *args)
    edit_namespace_project_url(project.namespace, project, *args)
  end

  def issue_url(entity, *args)
    namespace_project_issue_url(entity.project.namespace, entity.project, entity, *args)
  end

  def merge_request_url(entity, *args)
    namespace_project_merge_request_url(entity.project.namespace, entity.project, entity, *args)
  end

  def project_snippet_url(entity, *args)
    namespace_project_snippet_url(entity.project.namespace, entity.project, entity, *args)
  end

  def toggle_subscription_path(entity, *args)
    if entity.is_a?(Issue)
      toggle_subscription_namespace_project_issue_path(entity.project.namespace, entity.project, entity)
    else
      toggle_subscription_namespace_project_merge_request_path(entity.project.namespace, entity.project, entity)
    end
  end
end

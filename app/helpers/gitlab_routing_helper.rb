# Shorter routing method for project and project items
# Since update to rails 4.1.9 we are now allowed to use `/` in project routing
# so we use nested routing for project resources which include project and
# project namespace. To avoid writing long methods every time we define shortcuts for
# some of routing.
#
# For example instead of this:
#
#   namespace_project_merge_request_path(merge_request.project.namespace, merge_request.project, merge_request)
#
# We can simply use shortcut:
#
#   merge_request_path(merge_request)
#
module GitlabRoutingHelper
  # Project
  def project_path(project, *args)
    namespace_project_path(project.namespace, project, *args)
  end

  def project_url(project, *args)
    namespace_project_url(project.namespace, project, *args)
  end

  def edit_project_path(project, *args)
    edit_namespace_project_path(project.namespace, project, *args)
  end

  def edit_project_url(project, *args)
    edit_namespace_project_url(project.namespace, project, *args)
  end

  def project_files_path(project, *args)
    namespace_project_tree_path(project.namespace, project, @ref || project.repository.root_ref)
  end

  def project_commits_path(project, *args)
    namespace_project_commits_path(project.namespace, project, @ref || project.repository.root_ref)
  end

  def project_pipelines_path(project, *args)
    namespace_project_pipelines_path(project.namespace, project, *args)
  end

  def project_environments_path(project, *args)
    namespace_project_environments_path(project.namespace, project, *args)
  end

  def project_builds_path(project, *args)
    namespace_project_builds_path(project.namespace, project, *args)
  end

  def project_container_registry_path(project, *args)
    namespace_project_container_registry_index_path(project.namespace, project, *args)
  end

  def activity_project_path(project, *args)
    activity_namespace_project_path(project.namespace, project, *args)
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

  ## Members
  def project_members_url(project, *args)
    namespace_project_project_members_url(project.namespace, project)
  end

  def project_member_path(project_member, *args)
    namespace_project_project_member_path(project_member.source.namespace, project_member.source, project_member)
  end

  def request_access_project_members_path(project, *args)
    request_access_namespace_project_project_members_path(project.namespace, project)
  end

  def leave_project_members_path(project, *args)
    leave_namespace_project_project_members_path(project.namespace, project)
  end

  def approve_access_request_project_member_path(project_member, *args)
    approve_access_request_namespace_project_project_member_path(project_member.source.namespace, project_member.source, project_member)
  end

  def resend_invite_project_member_path(project_member, *args)
    resend_invite_namespace_project_project_member_path(project_member.source.namespace, project_member.source, project_member)
  end

  # Groups

  ## Members
  def group_members_url(group, *args)
    group_group_members_url(group, *args)
  end

  def group_member_path(group_member, *args)
    group_group_member_path(group_member.source, group_member)
  end

  def request_access_group_members_path(group, *args)
    request_access_group_group_members_path(group)
  end

  def leave_group_members_path(group, *args)
    leave_group_group_members_path(group)
  end

  def approve_access_request_group_member_path(group_member, *args)
    approve_access_request_group_group_member_path(group_member.source, group_member)
  end

  def resend_invite_group_member_path(group_member, *args)
    resend_invite_group_group_member_path(group_member.source, group_member)
  end

  # Artifacts

  def artifacts_action_path(path, project, build)
    action, path_params = path.split('/', 2)
    args = [project.namespace, project, build, path_params]

    case action
    when 'download'
      download_namespace_project_build_artifacts_path(*args)
    when 'browse'
      browse_namespace_project_build_artifacts_path(*args)
    when 'file'
      file_namespace_project_build_artifacts_path(*args)
    end
  end
end

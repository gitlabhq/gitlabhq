# Shorter routing method for some project items
module GitlabRoutingHelper
  extend ActiveSupport::Concern

  included do
    Gitlab::Routing.includes_helpers(self)
  end

  # Project
  def project_tree_path(project, ref = nil, *args)
    namespace_project_tree_path(project.namespace, project, ref || @ref || project.repository.root_ref, *args) # rubocop:disable Cop/ProjectPathHelper
  end

  def project_commits_path(project, ref = nil, *args)
    namespace_project_commits_path(project.namespace, project, ref || @ref || project.repository.root_ref, *args) # rubocop:disable Cop/ProjectPathHelper
  end

  def project_ref_path(project, ref_name, *args)
    project_commits_path(project, ref_name, *args)
  end

  def runners_path(project, *args)
    project_runners_path(project, *args)
  end

  def runner_path(runner, *args)
    project_runner_path(@project, runner, *args)
  end

  def environment_path(environment, *args)
    project_environment_path(environment.project, environment, *args)
  end

  def environment_metrics_path(environment, *args)
    metrics_project_environment_path(environment.project, environment, *args)
  end

  def issue_path(entity, *args)
    project_issue_path(entity.project, entity, *args)
  end

  def merge_request_path(entity, *args)
    project_merge_request_path(entity.project, entity, *args)
  end

  def pipeline_path(pipeline, *args)
    project_pipeline_path(pipeline.project, pipeline.id, *args)
  end

  def issue_url(entity, *args)
    project_issue_url(entity.project, entity, *args)
  end

  def merge_request_url(entity, *args)
    project_merge_request_url(entity.project, entity, *args)
  end

  def pipeline_url(pipeline, *args)
    project_pipeline_url(pipeline.project, pipeline.id, *args)
  end

  def pipeline_job_url(pipeline, build, *args)
    project_job_url(pipeline.project, build.id, *args)
  end

  def commits_url(entity, *args)
    project_commits_url(entity.project, entity.ref, *args)
  end

  def commit_url(entity, *args)
    project_commit_url(entity.project, entity.sha, *args)
  end

  def preview_markdown_path(parent, *args)
    return group_preview_markdown_path(parent) if parent.is_a?(Group)

    if @snippet.is_a?(PersonalSnippet)
      preview_markdown_snippets_path
    else
      preview_markdown_project_path(parent, *args)
    end
  end

  def edit_milestone_path(entity, *args)
    if entity.parent.is_a?(Group)
      edit_group_milestone_path(entity.parent, entity, *args)
    else
      edit_project_milestone_path(entity.parent, entity, *args)
    end
  end

  def toggle_subscription_path(entity, *args)
    if entity.is_a?(Issue)
      toggle_subscription_project_issue_path(entity.project, entity)
    else
      toggle_subscription_project_merge_request_path(entity.project, entity)
    end
  end

  def toggle_award_emoji_personal_snippet_path(*args)
    toggle_award_emoji_snippet_path(*args)
  end

  def toggle_award_emoji_namespace_project_project_snippet_path(*args)
    toggle_award_emoji_namespace_project_snippet_path(*args)
  end

  ## Members
  def project_members_url(project, *args)
    project_project_members_url(project, *args)
  end

  def project_member_path(project_member, *args)
    project_project_member_path(project_member.source, project_member)
  end

  def request_access_project_members_path(project, *args)
    request_access_project_project_members_path(project)
  end

  def leave_project_members_path(project, *args)
    leave_project_project_members_path(project)
  end

  def approve_access_request_project_member_path(project_member, *args)
    approve_access_request_project_project_member_path(project_member.source, project_member)
  end

  def resend_invite_project_member_path(project_member, *args)
    resend_invite_project_project_member_path(project_member.source, project_member)
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
    args = [project, build, path_params]

    case action
    when 'download'
      download_project_job_artifacts_path(*args)
    when 'browse'
      browse_project_job_artifacts_path(*args)
    when 'file'
      file_project_job_artifacts_path(*args)
    when 'raw'
      raw_project_job_artifacts_path(*args)
    end
  end

  # Pipeline Schedules
  def pipeline_schedules_path(project, *args)
    project_pipeline_schedules_path(project, *args)
  end

  def pipeline_schedule_path(schedule, *args)
    project = schedule.project
    project_pipeline_schedule_path(project, schedule, *args)
  end

  def edit_pipeline_schedule_path(schedule)
    project = schedule.project
    edit_project_pipeline_schedule_path(project, schedule)
  end

  def play_pipeline_schedule_path(schedule, *args)
    project = schedule.project
    play_project_pipeline_schedule_path(project, schedule, *args)
  end

  def take_ownership_pipeline_schedule_path(schedule, *args)
    project = schedule.project
    take_ownership_project_pipeline_schedule_path(project, schedule, *args)
  end
end

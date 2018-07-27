# frozen_string_literal: true

class GitTagPushService < BaseService
  attr_accessor :push_data

  def execute(update_statistics: true)
    project.repository.after_create if project.empty_repo?
    project.repository.before_push_tag

    @push_data = build_push_data

    EventCreateService.new.push(project, current_user, @push_data)
    Ci::CreatePipelineService.new(project, current_user, @push_data).execute(:push)

    SystemHooksService.new.execute_hooks(build_system_push_data.dup, :tag_push_hooks)
    project.execute_hooks(@push_data.dup, :tag_push_hooks)
    project.execute_services(@push_data.dup, :tag_push_hooks)

    if update_statistics
      ProjectCacheWorker.perform_async(project.id, [], [:commit_count, :repository_size])
    end

    true
  end

  private

  def build_push_data
    commits = []
    message = nil

    unless Gitlab::Git.blank_ref?(params[:newrev])
      tag_name = Gitlab::Git.ref_name(params[:ref])
      tag = project.repository.find_tag(tag_name)

      if tag && tag.target == params[:newrev]
        commit = project.commit(tag.dereferenced_target)
        commits = [commit].compact
        message = tag.message
      end
    end

    Gitlab::DataBuilder::Push.build(
      project,
      current_user,
      params[:oldrev],
      params[:newrev],
      params[:ref],
      commits,
      message)
  end

  def build_system_push_data
    Gitlab::DataBuilder::Push.build(
      project,
      current_user,
      params[:oldrev],
      params[:newrev],
      params[:ref],
      [],
      '')
  end
end

# frozen_string_literal: true

class GitTagPushService < BaseService
  def execute
    project.repository.after_create if project.empty_repo?
    project.repository.before_push_tag

    EventCreateService.new.push(project, current_user, push_data)
    Ci::CreatePipelineService.new(project, current_user, push_data).execute(:push)

    SystemHooksService.new.execute_hooks(system_push_data, :tag_push_hooks)
    project.execute_hooks(push_data.dup, :tag_push_hooks)
    project.execute_services(push_data.dup, :tag_push_hooks)

    ProjectCacheWorker.perform_async(project.id, [], [:commit_count, :repository_size])

    true
  end

  def push_data
    @push_data ||= begin
      commits = []
      message = nil

      unless Gitlab::Git.blank_ref?(params[:newrev])
        tag_name = Gitlab::Git.ref_name(params[:ref])
        tag = project.repository.find_tag(tag_name)

        if tag&.target == params[:newrev]
          commit = project.commit(tag.dereferenced_target)
          commits = [commit].compact
          message = tag.message
        end
      end

      build_data(commits, message)
    end
  end

  private

  def build_data(commits = [], message = '')
    Gitlab::DataBuilder::Push.build(
      project,
      current_user,
      params[:oldrev],
      params[:newrev],
      params[:ref],
      commits,
      message)
  end

  alias_method :system_push_data, :build_data
end

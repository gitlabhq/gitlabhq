class GeoRepositoryUpdateWorker
  include Sidekiq::Worker
  include Gitlab::ShellAdapter
  include DedicatedSidekiqQueue

  attr_accessor :project

  def perform(project_id, clone_url, push_data = nil)
    @project = Project.find(project_id)
    @push_data = push_data

    fetch_repository(clone_url)
    process_hooks if push_data # we should be compatible with old unprocessed data
  end

  private

  def fetch_repository(remote_url)
    @project.create_repository unless @project.repository_exists?
    @project.repository.after_create if @project.empty_repo?
    @project.repository.fetch_geo_mirror(remote_url)
  end

  def process_hooks
    if @push_data['type'] == 'push'
      branch = Gitlab::Git.ref_name(@push_data['ref'])
      process_push(branch, @push_data['after'])
    end
  end

  def process_push(branch, revision)
    @project.repository.after_push_commit(branch, revision)

    if push_remove_branch?
      @project.repository.after_remove_branch
    elsif push_to_new_branch?
      @project.repository.after_create_branch
    end

    ProjectCacheWorker.perform_async(@project.id)
  end

  def push_remove_branch?
    Gitlab::Git.branch_ref?(@push_data['ref']) && Gitlab::Git.blank_ref?(@push_data['after'])
  end

  def push_to_new_branch?
    Gitlab::Git.branch_ref?(@push_data['ref']) && Gitlab::Git.blank_ref?(@push_data['before'])
  end
end

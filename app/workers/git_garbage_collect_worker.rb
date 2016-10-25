class GitGarbageCollectWorker
  include Sidekiq::Worker
  include Gitlab::ShellAdapter
  include DedicatedSidekiqQueue

  sidekiq_options retry: false

  def perform(project_id)
    project = Project.find(project_id)

    gitlab_shell.gc(project.repository_storage_path, project.path_with_namespace)
    # Refresh the branch cache in case garbage collection caused a ref lookup to fail
    project.repository.after_create_branch
    project.repository.branch_names
    project.repository.has_visible_content?
  end
end

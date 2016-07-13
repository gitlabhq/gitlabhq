class GitGarbageCollectWorker
  include Sidekiq::Worker
  include Gitlab::ShellAdapter

  sidekiq_options queue: :gitlab_shell, retry: false

  def perform(project_id)
    project = Project.find(project_id)

    gitlab_shell.gc(project.repository_storage_path, project.path_with_namespace)
    # Expire the branch cache in case garbage collection caused a ref lookup to fail
    project.repository.after_create_branch
  end
end

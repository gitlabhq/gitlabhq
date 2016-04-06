class SingleRepositoryCheckWorker
  include Sidekiq::Worker

  sidekiq_options retry: false

  def perform(project_id)
    project = Project.find(project_id)
    update(project, success: check(project))
  end

  private

  def check(project)
    [project.repository.path_to_repo, project.wiki.wiki.path].all? do |path|
      git_fsck(path)
    end
  end

  def git_fsck(path)
    cmd = %W(nice git --git-dir=#{path} fsck)
    output, status = Gitlab::Popen.popen(cmd)
    return true if status.zero?

    Gitlab::RepositoryCheckLogger.error("command failed: #{cmd.join(' ')}\n#{output}")
    false
  end

  def update(project, success:)
    project.update_columns(
      last_repository_check_failed: !success,
      last_repository_check_at: Time.now,
    )
  end
end

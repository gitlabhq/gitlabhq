module RepositoryCheck
  class SingleRepositoryWorker
    include Sidekiq::Worker
  
    sidekiq_options retry: false
  
    def perform(project_id)
      project = Project.find(project_id)
      project.update_columns(
        last_repository_check_failed: !check(project),
        last_repository_check_at: Time.now,
      )
    end
  
    private
  
    def check(project)
      repositories = [project.repository]
      repositories << project.wiki.repository if project.wiki_enabled?
      # Use 'map do', not 'all? do', to prevent short-circuiting
      repositories.map { |repository| git_fsck(repository.path_to_repo) }.all?
    end
  
    def git_fsck(path)
      cmd = %W(nice git --git-dir=#{path} fsck)
      output, status = Gitlab::Popen.popen(cmd)
  
      if status.zero?
        true
      else
        Gitlab::RepositoryCheckLogger.error("command failed: #{cmd.join(' ')}\n#{output}")
        false
      end
    end
  end
end

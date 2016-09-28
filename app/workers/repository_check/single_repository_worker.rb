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
      if has_pushes?(project) && !git_fsck(project.repository)
        false
      elsif project.wiki_enabled?
        # Historically some projects never had their wiki repos initialized;
        # this happens on project creation now. Let's initialize an empty repo
        # if it is not already there.
        begin
          project.create_wiki
        rescue Rugged::RepositoryError
        end

        git_fsck(project.wiki.repository)
      else
        true
      end
    end

    def git_fsck(repository)
      path = repository.path_to_repo
      cmd = %W[nice git --git-dir=#{path} fsck]
      output, status = Gitlab::Popen.popen(cmd)

      if status.zero?
        true
      else
        Gitlab::RepositoryCheckLogger.error("command failed: #{cmd.join(' ')}\n#{output}")
        false
      end
    end

    def has_pushes?(project)
      Project.with_push.exists?(project.id)
    end
  end
end

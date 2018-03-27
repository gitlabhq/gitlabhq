module RepositoryCheck
  class SingleRepositoryWorker
    include ApplicationWorker
    include RepositoryCheckQueue

    def perform(project_id)
      project = Project.find(project_id)
      project.update_columns(
        last_repository_check_failed: !check(project),
        last_repository_check_at: Time.now
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
        project.create_wiki

        git_fsck(project.wiki.repository)
      else
        true
      end
    end

    def git_fsck(repository)
      return false unless repository.exists?

      repository.raw_repository.fsck

      true
    rescue Gitlab::Git::Repository::GitError => e
      Gitlab::RepositoryCheckLogger.error(e.message)
      false
    end

    def has_pushes?(project)
      Project.with_push.exists?(project.id)
    end
  end
end

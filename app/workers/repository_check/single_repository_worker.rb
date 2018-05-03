module RepositoryCheck
  class SingleRepositoryWorker
    include ApplicationWorker
    include RepositoryCheckQueue

    prepend ::EE::RepositoryCheck::SingleRepositoryWorker

    def perform(project_id)
      project = Project.find(project_id)
      healthy = project_healthy?(project)

      update_repository_check_status(project, healthy)
    end

    private

    def update_repository_check_status(project, healthy)
      project.update_columns(
        last_repository_check_failed: !healthy,
        last_repository_check_at: Time.now
      )
    end

    def project_healthy?(project)
      repo_healthy?(project) && wiki_repo_healthy?(project)
    end

    def repo_healthy?(project)
      return true if project.empty_repo?

      git_fsck(project.repository)
    end

    def wiki_repo_healthy?(project)
      return true unless project.wiki_enabled?

      # Historically some projects never had their wiki repos initialized;
      # this happens on project creation now. Let's initialize an empty repo
      # if it is not already there.
      project.create_wiki

      git_fsck(project.wiki.repository)
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

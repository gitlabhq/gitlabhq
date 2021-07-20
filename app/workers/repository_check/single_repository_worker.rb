# frozen_string_literal: true

module RepositoryCheck
  class SingleRepositoryWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    sidekiq_options retry: 3
    include RepositoryCheckQueue

    def perform(project_id)
      project = Project.find(project_id)
      healthy = project_healthy?(project)

      update_repository_check_status(project, healthy)
    end

    private

    def update_repository_check_status(project, healthy)
      project.update_columns(
        last_repository_check_failed: !healthy,
        last_repository_check_at: Time.current
      )
    end

    def project_healthy?(project)
      repo_healthy?(project) && wiki_repo_healthy?(project)
    end

    def repo_healthy?(project)
      return true unless has_changes?(project)

      git_fsck(project.repository)
    end

    def wiki_repo_healthy?(project)
      return true unless has_wiki_changes?(project)

      git_fsck(project.wiki.repository)
    end

    def git_fsck(repository)
      return false unless repository.exists?

      repository.raw_repository.fsck

      true
    rescue Gitlab::Git::Repository::GitError => e
      Gitlab::RepositoryCheckLogger.error("#{repository.full_path}: #{e.message}")
      false
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def has_changes?(project)
      Project.with_push.exists?(project.id)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def has_wiki_changes?(project)
      return false unless project.wiki_enabled?

      # Historically some projects never had their wiki repos initialized;
      # this happens on project creation now. Let's initialize an empty repo
      # if it is not already there.
      return false unless project.create_wiki

      has_changes?(project)
    end
  end
end

RepositoryCheck::SingleRepositoryWorker.prepend_mod_with('RepositoryCheck::SingleRepositoryWorker')

module EE
  module Projects
    module DestroyService
      def execute
        raise NotImplementedError unless defined?(super)

        succeeded = super

        if succeeded
          mirror_cleanup(project)
          log_geo_event(project)
          log_audit_event(project)
        end

        succeeded
      end

      def mirror_cleanup(project)
        return unless project.mirror?

        ::Gitlab::Mirror.decrement_capacity(project.id)
      end

      def log_geo_event(project)
        ::Geo::RepositoryDeletedEventStore.new(
          project,
          repo_path: repo_path,
          wiki_path: wiki_path
        ).create
      end

      # Removes physical repository in a Geo replicated secondary node
      # There is no need to do any database operation as it will be
      # replicated by itself.
      def geo_replicate
        return unless ::Gitlab::Geo.secondary?

        # Flush the cache for both repositories. This has to be done _before_
        # removing the physical repositories as some expiration code depends on
        # Git data (e.g. a list of branch names).
        flush_caches(project)

        trash_repositories!
        trash_repositories_cleanup!

        log_info("Project \"#{project.name}\" was removed")
      end

      private

      # When we remove project we move the repository to path+deleted.git
      # then outside the transaction we schedule removal of path+deleted
      # with Sidekiq through the after_commit callback. In a Geo secondary
      # node we don't have access to the original model anymore then we
      # rebuild a Geo::DeletedProject model. Since this model is read-only,
      # this callback will not be triggered letting us with stalled
      # repositories on disk.
      def trash_repositories_cleanup!
        repo_removed_path = removal_path(repo_path)

        if gitlab_shell.exists?(repository_storage_path, repo_removed_path + '.git')
          GitlabShellWorker.perform_in(5.minutes, :remove_repository, repository_storage_path, repo_removed_path)
        end

        wiki_removed_path = removal_path(wiki_path)

        if gitlab_shell.exists?(repository_storage_path, wiki_removed_path + '.git')
          GitlabShellWorker.perform_in(5.minutes, :remove_repository, repository_storage_path, wiki_removed_path)
        end
      end

      def repository_storage_path
        project.repository_storage_path
      end

      def log_audit_event(project)
        ::AuditEventService.new(
          current_user,
          project,
          action: :destroy
        ).for_project.security_event
      end
    end
  end
end

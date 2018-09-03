module Geo
  class RepositorySyncService < BaseSyncService
    self.type = :repository

    private

    def sync_repository
      fetch_repository
      update_default_branch
      mark_sync_as_successful
    rescue Gitlab::Shell::Error => e
      # In some cases repository does not exist, the only way to know about this is to parse the error text.
      # If it does not exist we should consider it as successfully downloaded.
      if e.message.include? Gitlab::GitAccess::ERROR_MESSAGES[:no_repo]
        log_info('Repository is not found, marking it as successfully synced')
        mark_sync_as_successful(missing_on_primary: true)
      else
        fail_registry!('Error syncing repository', e)
      end
    rescue Gitlab::Git::Repository::NoRepository => e
      log_info('Setting force_to_redownload flag')
      fail_registry!('Invalid repository', e, force_to_redownload_repository: true)

      log_info('Expiring caches')
      project.repository.after_create
    ensure
      expire_repository_caches
      execute_housekeeping
    end

    def expire_repository_caches
      log_info('Expiring caches')
      project.repository.after_sync
    end

    def ssh_url_to_repo
      "#{primary_ssh_path_prefix}#{project.full_path}.git"
    end

    def repository
      project.repository
    end

    def ensure_repository
      project.ensure_repository
    end

    # Update the default branch querying the remote to determine its HEAD
    def update_default_branch
      root_ref = repository.find_remote_root_ref(GEO_REMOTE_NAME)
      project.change_head(root_ref) if root_ref.present?
    end

    def schedule_repack
      GitGarbageCollectWorker.perform_async(@project.id, :full_repack, lease_key)
    end

    def execute_housekeeping
      Geo::ProjectHousekeepingService.new(project).execute
    end
  end
end

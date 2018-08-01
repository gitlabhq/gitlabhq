require 'securerandom'

module Geo
  class BaseSyncService
    include ExclusiveLeaseGuard
    include ::Gitlab::Geo::ProjectLogHelpers
    include ::Gitlab::ShellAdapter
    include Delay

    class << self
      attr_accessor :type
    end

    attr_reader :project

    GEO_REMOTE_NAME = 'geo'.freeze
    LEASE_TIMEOUT    = 8.hours.freeze
    LEASE_KEY_PREFIX = 'geo_sync_service'.freeze

    def initialize(project)
      @project = project
    end

    def execute
      try_obtain_lease do
        log_info("Started #{type} sync")

        sync_repository

        log_info("Finished #{type} sync")
      end
    end

    def lease_key
      @lease_key ||= "#{LEASE_KEY_PREFIX}:#{type}:#{project.id}"
    end

    def lease_timeout
      LEASE_TIMEOUT
    end

    private

    def fetch_repository
      log_info("Trying to fetch #{type}")
      clean_up_temporary_repository

      log_info("Marking #{type} sync as started")

      registry.start_sync!(type)

      if redownload?
        redownload_repository
        schedule_repack
      elsif repository.exists?
        fetch_geo_mirror(repository)
      else
        ensure_repository
        fetch_geo_mirror(repository)
        schedule_repack
      end
    end

    def redownload?
      registry.should_be_redownloaded?(type)
    end

    def schedule_repack
      raise NotImplementedError
    end

    def redownload_repository
      log_info("Redownloading #{type}")

      return if fetch_snapshot

      log_info("Attempting to fetch repository via git")

      # `git fetch` needs an empty bare repository to fetch into
      unless gitlab_shell.create_repository(project.repository_storage, disk_path_temp)
        raise Gitlab::Shell::Error, 'Can not create a temporary repository'
      end

      fetch_geo_mirror(temp_repo)

      set_temp_repository_as_main
    ensure
      clean_up_temporary_repository
    end

    def current_node
      ::Gitlab::Geo.current_node
    end

    def fetch_geo_mirror(repository)
      url = Gitlab::Geo.primary_node.url + repository.full_path + '.git'

      # Fetch the repository, using a JWT header for authentication
      authorization = ::Gitlab::Geo::RepoSyncRequest.new.authorization
      header = { "http.#{url}.extraHeader" => "Authorization: #{authorization}" }

      repository.with_config(header) do
        repository.fetch_as_mirror(url, remote_name: GEO_REMOTE_NAME, forced: true)
      end
    end

    # Use snapshotting for redownloads *only* when enabled.
    #
    # If writes happen to the repository while snapshotting, it may be
    # returned in an inconsistent state. However, a subsequent git fetch
    # will be enqueued by the log cursor, which should resolve any problems
    # it is possible to fix.
    def fetch_snapshot
      log_info("Attempting to fetch repository via snapshot")

      temp_repo.create_from_snapshot(
        ::Gitlab::Geo.primary_node.snapshot_url(temp_repo),
        ::Gitlab::Geo::RepoSyncRequest.new.authorization
      )
    rescue => err
      log_error('Snapshot attempt failed', err)
      false
    end

    def registry
      @registry ||= Geo::ProjectRegistry.find_or_initialize_by(project_id: project.id)
    end

    def mark_sync_as_successful(missing_on_primary: false)
      log_info("Marking #{type} sync as successful")

      persisted = registry.finish_sync!(type, missing_on_primary)

      reschedule_sync unless persisted

      log_info("Finished #{type} sync",
               update_delay_s: update_delay_in_seconds,
               download_time_s: download_time_in_seconds)
    end

    def reschedule_sync
      log_info("Reschedule #{type} sync because a RepositoryUpdateEvent was processed during the sync")

      ::Geo::ProjectSyncWorker.perform_async(project.id, Time.now)
    end

    def fail_registry!(message, error, attrs = {})
      log_error(message, error)

      registry.fail_sync!(type, message, error, attrs)

      repository.clean_stale_repository_files
    end

    def type
      self.class.type
    end

    def update_delay_in_seconds
      # We don't track the last update time of repositories and Wiki
      # separately in the main database
      return unless project.last_repository_updated_at

      (last_successful_sync_at.to_f - project.last_repository_updated_at.to_f).round(3)
    end

    def download_time_in_seconds
      (last_successful_sync_at.to_f - last_synced_at.to_f).round(3)
    end

    def last_successful_sync_at
      registry.public_send("last_#{type}_successful_sync_at") # rubocop:disable GitlabSecurity/PublicSend
    end

    def last_synced_at
      registry.public_send("last_#{type}_synced_at") # rubocop:disable GitlabSecurity/PublicSend
    end

    def disk_path_temp
      # We use "@" as it's not allowed to use it in a group or project name
      @disk_path_temp ||= "@geo-temporary/#{repository.disk_path}"
    end

    def deleted_disk_path_temp
      @deleted_path ||= "@failed-geo-sync/#{repository.disk_path}"
    end

    def temp_repo
      @temp_repo ||= ::Repository.new(repository.full_path, repository.project, disk_path: disk_path_temp, is_wiki: repository.is_wiki)
    end

    def clean_up_temporary_repository
      exists = gitlab_shell.exists?(project.repository_storage, disk_path_temp + '.git')

      if exists && !gitlab_shell.remove_repository(project.repository_storage, disk_path_temp)
        raise Gitlab::Shell::Error, "Temporary #{type} can not be removed"
      end
    end

    def set_temp_repository_as_main
      log_info(
        "Setting newly downloaded repository as main",
        storage_shard: project.repository_storage,
        temp_path: disk_path_temp,
        deleted_disk_path_temp: deleted_disk_path_temp,
        disk_path: repository.disk_path
      )

      # Remove the deleted path in case it exists, but it may not be there
      gitlab_shell.remove_repository(project.repository_storage, deleted_disk_path_temp)

      # Make sure we have the most current state of exists?
      repository.expire_exists_cache

      # Move the current canonical repository to the deleted path for reference
      if repository.exists?
        ensure_repository_namespace(deleted_disk_path_temp)

        unless gitlab_shell.mv_repository(project.repository_storage, repository.disk_path, deleted_disk_path_temp)
          raise Gitlab::Shell::Error, 'Can not move original repository out of the way'
        end
      end

      # Move the temporary repository to the canonical path

      ensure_repository_namespace(repository.disk_path)

      unless gitlab_shell.mv_repository(project.repository_storage, disk_path_temp, repository.disk_path)
        raise Gitlab::Shell::Error, 'Can not move temporary repository to canonical location'
      end

      # Purge the original repository
      unless gitlab_shell.remove_repository(project.repository_storage, deleted_disk_path_temp)
        raise Gitlab::Shell::Error, 'Can not remove outdated main repository'
      end
    end

    def ensure_repository_namespace(disk_path)
      gitlab_shell.add_namespace(
        project.repository_storage,
        File.dirname(disk_path)
      )
    end
  end
end

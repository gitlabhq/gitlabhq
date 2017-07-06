module Geo
  class BaseSyncService
    class << self
      attr_accessor :type
    end

    attr_reader :project

    LEASE_TIMEOUT    = 8.hours.freeze
    LEASE_KEY_PREFIX = 'geo_sync_service'.freeze

    def initialize(project)
      @project = project
    end

    def execute
      try_obtain_lease do
        log("Started #{type} sync")
        sync_repository
        log("Finished #{type} sync")
      end
    end

    private

    def registry
      @registry ||= Geo::ProjectRegistry.find_or_initialize_by(project_id: project.id)
    end

    def try_obtain_lease
      log("Trying to obtain lease to sync #{type}")
      repository_lease = Gitlab::ExclusiveLease.new(lease_key, timeout: LEASE_TIMEOUT).try_obtain

      unless repository_lease
        log("Could not obtain lease to sync #{type}")
        return
      end

      yield

      # We should release the lease for a repository, only if we have obtained
      # it. If something went wrong when syncing the repository, we should wait
      # for the lease timeout to try again.
      log("Releasing leases to sync #{type}")
      Gitlab::ExclusiveLease.cancel(lease_key, repository_lease)
    end

    def update_registry(type, started_at: nil, finished_at: nil)
      return unless started_at || finished_at

      log("Updating #{type} sync information")

      attrs = {}.tap do |attrs|
        if started_at
          attrs["last_#{type}_synced_at"] = started_at
        end

        if finished_at
          attrs["last_#{type}_successful_sync_at"] = finished_at
          attrs["resync_#{type}"] = false
        end
      end

      registry.update!(attrs)
    end

    def lease_key
      @lease_key ||= "#{LEASE_KEY_PREFIX}:#{type}:#{project.id}"
    end

    def type
      self.class.type
    end

    def primary_ssh_path_prefix
      @primary_ssh_path_prefix ||= Gitlab::Geo.primary_node.clone_url_prefix
    end

    def log(message)
      Rails.logger.info("#{self.class.name}: #{message} for project #{project.path_with_namespace} (#{project.id})")
    end
  end
end

module Geo
  # The clone_url_prefix is used to build URLs for the Geo synchronization
  # If this is missing from the primary node we raise this exception
  EmptyCloneUrlPrefixError = Class.new(StandardError)

  class BaseSyncService
    include ::Gitlab::Geo::ProjectLogHelpers

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
        log_info("Started #{type} sync")
        sync_repository
        log_info("Finished #{type} sync")
      end
    end

    def lease_key
      @lease_key ||= "#{LEASE_KEY_PREFIX}:#{type}:#{project.id}"
    end

    def primary_ssh_path_prefix
      @primary_ssh_path_prefix ||= Gitlab::Geo.primary_node.clone_url_prefix.tap do |prefix|
        raise EmptyCloneUrlPrefixError, 'Missing clone_url_prefix in the primary node' unless prefix.present?
      end
    end

    def primary_http_path_prefix
      @primary_http_path_prefix ||= Gitlab::Geo.primary_node.url
    end

    private

    def sync_repository
      raise NotImplementedError, 'This class should implement sync_repository method'
    end

    def current_node
      ::Gitlab::Geo.current_node
    end

    def fetch_geo_mirror(repository)
      case current_node&.clone_protocol
      when 'http'
        fetch_http_geo_mirror(repository)
      when 'ssh'
        fetch_ssh_geo_mirror(repository)
      else
        raise "Unknown clone protocol: #{current_node&.clone_protocol}"
      end
    end

    def build_repository_url(prefix, repository)
      url = prefix
      url += '/' unless url.end_with?('/')

      url + repository.full_path + '.git'
    end

    def fetch_http_geo_mirror(repository)
      url = build_repository_url(primary_http_path_prefix, repository)

      # Fetch the repository, using a JWT header for authentication
      authorization = ::Gitlab::Geo::BaseRequest.new.authorization
      header = { "http.#{url}.extraHeader" => "Authorization: #{authorization}" }

      repository.with_config(header) { repository.fetch_geo_mirror(url) }
    end

    def fetch_ssh_geo_mirror(repository)
      url = build_repository_url(primary_ssh_path_prefix, repository)

      repository.fetch_geo_mirror(url)
    end

    def registry
      @registry ||= Geo::ProjectRegistry.find_or_initialize_by(project_id: project.id)
    end

    def try_obtain_lease
      log_info("Trying to obtain lease to sync #{type}")
      repository_lease = Gitlab::ExclusiveLease.new(lease_key, timeout: LEASE_TIMEOUT).try_obtain

      unless repository_lease
        log_info("Could not obtain lease to sync #{type}")
        return
      end

      yield

      # We should release the lease for a repository, only if we have obtained
      # it. If something went wrong when syncing the repository, we should wait
      # for the lease timeout to try again.
      log_info("Releasing leases to sync #{type}")
      Gitlab::ExclusiveLease.cancel(lease_key, repository_lease)
    end

    def update_registry(started_at: nil, finished_at: nil)
      return unless started_at || finished_at

      log_info("Updating #{type} sync information")

      attrs = {}

      attrs["last_#{type}_synced_at"] = started_at if started_at

      if finished_at
        attrs["last_#{type}_successful_sync_at"] = finished_at
        attrs["resync_#{type}"] = false
      end

      registry.update!(attrs)
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
  end
end

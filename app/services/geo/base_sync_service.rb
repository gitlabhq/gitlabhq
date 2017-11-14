require 'securerandom'

module Geo
  # The clone_url_prefix is used to build URLs for the Geo synchronization
  # If this is missing from the primary node we raise this exception
  EmptyCloneUrlPrefixError = Class.new(StandardError)

  class BaseSyncService
    include ExclusiveLeaseGuard
    include ::Gitlab::Geo::ProjectLogHelpers
    include Delay

    class << self
      attr_accessor :type
    end

    attr_reader :project

    LEASE_TIMEOUT    = 8.hours.freeze
    LEASE_KEY_PREFIX = 'geo_sync_service'.freeze
    RETRY_BEFORE_REDOWNLOAD = 5
    RETRY_LIMIT = 8

    def initialize(project)
      @project = project
    end

    def execute
      try_obtain_lease do
        log_info("Started #{type} sync")

        if should_be_retried?
          sync_repository
        elsif should_be_redownloaded?
          sync_repository(true)
        else
          # Clean up the state of sync to start a new cycle
          registry.delete
          log_info("Clean up #{type} sync status")
          return
        end

        log_info("Finished #{type} sync")
      end
    end

    def lease_key
      @lease_key ||= "#{LEASE_KEY_PREFIX}:#{type}:#{project.id}"
    end

    def lease_timeout
      LEASE_TIMEOUT
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

    def retry_count
      registry.public_send("#{type}_retry_count") || 0 # rubocop:disable GitlabSecurity/PublicSend
    end

    def should_be_retried?
      return false if registry.public_send("force_to_redownload_#{type}")  # rubocop:disable GitlabSecurity/PublicSend

      retry_count <= RETRY_BEFORE_REDOWNLOAD
    end

    def should_be_redownloaded?
      return true if registry.public_send("force_to_redownload_#{type}") # rubocop:disable GitlabSecurity/PublicSend

      (RETRY_BEFORE_REDOWNLOAD..RETRY_LIMIT) === retry_count
    end

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

    def update_registry(started_at: nil, finished_at: nil)
      return unless started_at || finished_at

      log_info("Updating #{type} sync information")

      attrs = {}

      if started_at
        attrs["last_#{type}_synced_at"] = started_at
        attrs["#{type}_retry_count"] = retry_count + 1
        attrs["#{type}_retry_at"] = Time.now + delay(attrs["#{type}_retry_count"]).seconds
      end

      if finished_at
        attrs["last_#{type}_successful_sync_at"] = finished_at
        attrs["resync_#{type}"] = false
        attrs["#{type}_retry_count"] = nil
        attrs["#{type}_retry_at"] = nil
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

    def disk_path_temp
      unless @disk_path_temp
        random_string = SecureRandom.hex(7)
        @disk_path_temp = "#{repository.disk_path}_#{random_string}"
      end

      @disk_path_temp
    end

    def build_temporary_repository
      unless gitlab_shell.add_repository(project.repository_storage, disk_path_temp)
        raise Gitlab::Shell::Error, 'Can not create a temporary repository'
      end

      repository.clone.tap { |repo| repo.disk_path = disk_path_temp }
    end

    def clean_up_temporary_repository
      gitlab_shell.remove_repository(project.repository_storage_path, disk_path_temp)
    end

    def set_temp_repository_as_main
      log_info(
        "Setting newly downloaded repository as main",
        storage_path: project.repository_storage_path,
        temp_path: disk_path_temp,
        disk_path: repository.disk_path
      )

      unless gitlab_shell.remove_repository(project.repository_storage_path, repository.disk_path)
        raise Gitlab::Shell::Error, 'Can not remove outdated main repository to replace it'
      end

      unless gitlab_shell.mv_repository(project.repository_storage_path, disk_path_temp, repository.disk_path)
        raise Gitlab::Shell::Error, 'Can not move temporary repository'
      end
    end
  end
end

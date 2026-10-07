# frozen_string_literal: true

module Gitaly
  class Server
    # Matches a version string carrying a Git revision suffix, as produced by
    # `git describe` on a full clone (`1.55.6-45-g594c3ea3`) or by the Gitaly
    # Makefile fallback on a shallow clone (`19.4.1-g7985a4e`,
    # `19.5.0-rc2-g5a2cb57`). See https://gitlab.com/gitlab-org/gitaly/-/merge_requests/9173.
    VERSION_WITH_REVISION_REGEX = /\A(?<version>\d+\.\d+\.\d+(?:-[0-9A-Za-z.]+)*?)-g(?<revision>[a-f0-9]{5,40})\z/
    DEFAULT_REPLICATION_FACTOR = 1

    ServerSignature = Struct.new(:public_key, :error, keyword_init: true)

    class << self
      def all
        Gitlab.config.repositories.storages.keys.map { |s| Gitaly::Server.new(s) }
      end

      def count
        all.size
      end

      def filesystems
        all.map(&:filesystem_type).compact.uniq
      end

      def gitaly_clusters
        all.count { |g| g.replication_factor > DEFAULT_REPLICATION_FACTOR }
      end
    end

    attr_reader :storage

    def initialize(storage)
      @storage = storage
    end

    def server_version
      info.server_version
    end

    def git_binary_version
      info.git_version
    end

    def expected_version?
      server_version == Gitlab::GitalyClient.expected_server_version || matches_version_with_revision?
    end
    alias_method :up_to_date?, :expected_version?

    def read_writeable?
      readable? && writeable?
    end

    def readable?
      storage_status&.readable
    end

    def writeable?
      storage_status&.writeable
    end

    def filesystem_type
      storage_status&.fs_type
    end

    def server_signature_public_key
      server_signature&.public_key
    end

    def server_signature_error?
      !!server_signature.try(:error)
    end

    def disk_used
      disk_statistics_storage_status&.used
    end

    def disk_available
      disk_statistics_storage_status&.available
    end

    # Simple convenience method for when obtaining both used and available
    # statistics at once is preferred.
    def disk_stats
      disk_statistics_storage_status
    end

    # The node's own address, not the gitway hop that may sit in front of it: this is shown
    # beside disk and replication stats that are read from the node itself.
    def address
      Gitlab::GitalyClient.gitaly_address(@storage)
    rescue RuntimeError => e
      "Error getting the address: #{e.message}"
    end

    def replication_factor
      storage_status&.replication_factor
    end

    private

    def storage_status
      @storage_status ||= info.storage_statuses.find { |s| s.storage_name == storage }
    end

    def disk_statistics_storage_status
      @disk_statistics_storage_status ||= disk_statistics.storage_statuses.find { |s| s.storage_name == storage }
    end

    # A server version with a revision suffix is up to date when either:
    # - its semantic version equals the expected version (tagged releases,
    #   where GITALY_SERVER_VERSION is e.g. `19.4.1`), or
    # - the expected version is a commit SHA that starts with the revision
    #   (auto-deploy, where GITALY_SERVER_VERSION is a full SHA).
    def matches_version_with_revision?
      match = server_version.match(VERSION_WITH_REVISION_REGEX)
      return false unless match

      expected = Gitlab::GitalyClient.expected_server_version

      match[:version] == expected || expected.start_with?(match[:revision])
    end

    def server_signature
      @server_signature ||= begin
        Gitlab::GitalyClient::ServerService.new(@storage).server_signature
      rescue GRPC::Unavailable, GRPC::DeadlineExceeded
        ServerSignature.new(public_key: nil, error: true)
      end
    end

    def info
      @info ||= wrapper_gitaly_rpc_errors do
        Gitlab::GitalyClient::ServerService.new(@storage).info
      end
    end

    def disk_statistics
      @disk_statistics ||= wrapper_gitaly_rpc_errors do
        Gitlab::GitalyClient::ServerService.new(@storage).disk_statistics
      end
    end

    def wrapper_gitaly_rpc_errors
      yield
    rescue GRPC::Unavailable, GRPC::DeadlineExceeded => ex
      Gitlab::ErrorTracking.track_exception(ex)
      # This will show the server as being out of date
      Gitaly::ServerInfoResponse.new(git_version: '', server_version: '', storage_statuses: [])
    end
  end
end

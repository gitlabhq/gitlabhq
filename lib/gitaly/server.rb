# frozen_string_literal: true

module Gitaly
  class Server
    SHA_VERSION_REGEX = /\A\d+\.\d+\.\d+-\d+-g([a-f0-9]{8})\z/
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
      server_version == Gitlab::GitalyClient.expected_server_version || matches_sha?
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

    def address
      Gitlab::GitalyClient.address(@storage)
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

    def matches_sha?
      match = server_version.match(SHA_VERSION_REGEX)
      return false unless match

      Gitlab::GitalyClient.expected_server_version.start_with?(match[1])
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

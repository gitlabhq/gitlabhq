# frozen_string_literal: true

module Gitaly
  class Server
    SHA_VERSION_REGEX = /\A\d+\.\d+\.\d+-\d+-g([a-f0-9]{8})\z/.freeze

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

    def address
      Gitlab::GitalyClient.address(@storage)
    rescue RuntimeError => e
      "Error getting the address: #{e.message}"
    end

    private

    def storage_status
      @storage_status ||= info.storage_statuses.find { |s| s.storage_name == storage }
    end

    def matches_sha?
      match = server_version.match(SHA_VERSION_REGEX)
      return false unless match

      Gitlab::GitalyClient.expected_server_version.start_with?(match[1])
    end

    def info
      @info ||=
        begin
          Gitlab::GitalyClient::ServerService.new(@storage).info
        rescue GRPC::Unavailable, GRPC::DeadlineExceeded
          # This will show the server as being out of date
          Gitaly::ServerInfoResponse.new(git_version: '', server_version: '', storage_statuses: [])
        end
    end
  end
end

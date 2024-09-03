# frozen_string_literal: true

module Gitlab
  module GitalyClient
    # Meant for extraction of server data, and later maybe to perform misc task
    #
    # Not meant for connection logic, look in Gitlab::GitalyClient
    class ServerService
      def initialize(storage)
        @storage = storage
      end

      def info
        GitalyClient.call(@storage, :server_service, :server_info, Gitaly::ServerInfoRequest.new, timeout: GitalyClient.fast_timeout)
      end

      def disk_statistics
        GitalyClient.call(@storage, :server_service, :disk_statistics, Gitaly::DiskStatisticsRequest.new, timeout: GitalyClient.fast_timeout)
      end

      def server_signature
        GitalyClient.call(@storage, :server_service, :server_signature, Gitaly::ServerSignatureRequest.new, timeout: GitalyClient.fast_timeout)
      end

      def storage_info
        storage_specific(info)
      end

      def storage_disk_statistics
        storage_specific(disk_statistics)
      end

      private

      def storage_specific(response)
        response.storage_statuses.find { |status| status.storage_name == @storage }
      end
    end
  end
end

# frozen_string_literal: true

module Gitlab
  module GitalyClient
    class HealthCheckService
      def initialize(storage)
        @storage = storage
      end

      # Sends a gRPC health ping to the Gitaly server for the storage shard.
      def check
        request = Grpc::Health::V1::HealthCheckRequest.new
        response = GitalyClient.call(@storage, :health_check, :check, request, timeout: GitalyClient.fast_timeout)

        { success: response&.status == :SERVING }
      rescue GRPC::BadStatus => e
        { success: false, message: e.to_s }
      end
    end
  end
end

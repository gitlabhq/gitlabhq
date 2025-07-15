# frozen_string_literal: true

module Gitlab
  module TopologyServiceClient
    # Uses GRPC Health Checking Protocol. See https://github.com/grpc/grpc/blob/master/doc/health-checking.md
    class HealthService < BaseService
      # From https://github.com/grpc/grpc-proto/blob/master/grpc/health/v1/health.proto
      # UNKNOWN = 0
      # SERVING = 1
      # NOT_SERVING = 2
      SERVING_STATUS = :SERVING

      def service_healthy?
        response = service_class.check(health_check_request)

        Gitlab::AppLogger.info(message: "Topology Service status code is: #{response.status}")

        response.status == SERVING_STATUS
      rescue GRPC::Unavailable => e
        Gitlab::AppLogger.error(message: "Topology Service is UNAVAILABLE: #{e.message}")

        false
      end

      private

      def service_class
        @service_class ||= Grpc::Health::V1::Health::Stub.new(topology_service_address, service_credentials)
      end

      def health_check_request
        @health_check_request ||= Grpc::Health::V1::HealthCheckRequest.new
      end
    end
  end
end

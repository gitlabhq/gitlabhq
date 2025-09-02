# frozen_string_literal: true

module Gitlab
  module TopologyServiceClient
    class MetadataInterceptor < GRPC::ClientInterceptor
      def request_response(metadata:, **)
        Gitlab.config.cell.topology_service_client.metadata.each do |key, value|
          metadata[key] = value
        end

        yield
      end
    end
  end
end

# frozen_string_literal: true

module Gitlab
  module TopologyServiceClient
    DEFAULT_TIMEOUT_IN_SECONDS = 1

    class BaseService
      def initialize(timeout: nil)
        raise NotImplementedError unless enabled?

        @timeout = timeout
      end

      def cell_id
        @cell_id ||= Gitlab.config.cell.id
      end

      private

      def client
        @client ||= service_class.new(
          topology_service_address,
          service_credentials,
          interceptors: [
            Gitlab::Cells::TopologyService::MetadataClient.new(
              Gitlab.config.cell.topology_service_client.metadata)
          ],
          **options
        )
      end

      def options
        { timeout: @timeout || DEFAULT_TIMEOUT_IN_SECONDS }
      end

      def service_credentials
        return :this_channel_is_insecure unless topology_service_config.tls.enabled

        ca_file, key_file, cert_file = topology_service_config.values_at(
          'ca_file', 'private_key_file', 'certificate_file'
        )

        return GRPC::Core::ChannelCredentials.new unless key_file && cert_file
        return GRPC::Core::ChannelCredentials.new unless File.exist?(key_file) && File.exist?(cert_file)

        ca_cert_content = File.read(ca_file) if ca_file && File.exist?(ca_file)

        GRPC::Core::ChannelCredentials.new(ca_cert_content, File.read(key_file), File.read(cert_file))
      rescue Errno::EACCES => e
        raise "Failed to read certificate files: #{e.message}"
      end

      def topology_service_address
        topology_service_config.address
      end

      def enabled?
        Gitlab.config.cell.enabled
      end

      def topology_service_config
        @topology_service_config ||= Gitlab.config.cell.topology_service_client
      end
    end
  end
end

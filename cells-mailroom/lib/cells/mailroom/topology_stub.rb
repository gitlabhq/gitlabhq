# frozen_string_literal: true

require 'grpc'
require 'gitlab/cells/topology_service'

module Cells
  module Mailroom
    # Builds a configured ClassifyService gRPC stub for the Topology Service,
    # mirroring Gitlab::TopologyServiceClient::BaseService credential handling
    # but without depending on the Rails application.
    #
    # Classify is available to a regular cell identity, so no admin certificate
    # is required.
    module TopologyStub
      MAX_RECEIVE_MESSAGE_BYTES = 10 * 1024 * 1024

      CredentialsError = Class.new(StandardError)

      module_function

      def classify_stub(config)
        Gitlab::Cells::TopologyService::ClassifyService::Stub.new(
          config.topology_service_address,
          credentials(config),
          interceptors: interceptors(config),
          channel_args: { 'grpc.max_receive_message_length' => MAX_RECEIVE_MESSAGE_BYTES },
          timeout: 5
        )
      end

      # Builds mutual TLS credentials for the Topology Service channel. When TLS
      # is enabled we require a fully configured, readable client certificate and
      # key: a misconfiguration must fail loudly rather than silently fall back to
      # a degraded (non-mTLS) channel while the service keeps forwarding emails.
      def credentials(config)
        return :this_channel_is_insecure unless config.topology_service_tls_enabled?

        certs = config.topology_service_certs
        key_file = certs['private_key_file']
        cert_file = certs['certificate_file']
        ca_file = certs['ca_file']

        unless key_file && cert_file
          raise CredentialsError,
            'Topology Service TLS is enabled but private_key_file and/or certificate_file are not configured'
        end

        [key_file, cert_file].each do |path|
          raise CredentialsError, "Topology Service TLS credential file not found: #{path}" unless File.exist?(path)
        end

        ca = File.read(ca_file) if ca_file && File.exist?(ca_file)
        GRPC::Core::ChannelCredentials.new(ca, File.read(key_file), File.read(cert_file))
      rescue SystemCallError => e
        raise CredentialsError, "Failed to read Topology Service TLS credential files: #{e.message}"
      end

      def interceptors(config)
        metadata = config.topology_service_metadata
        return [] if metadata.empty?

        [Gitlab::Cells::TopologyService::MetadataClient.new(metadata)]
      end
    end
  end
end

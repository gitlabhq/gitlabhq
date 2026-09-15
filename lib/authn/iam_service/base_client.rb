# frozen_string_literal: true

module Authn
  module IamService
    # Shared transport for IAM gRPC clients. Builds a stub for a given service
    # and selects channel credentials from that service's `secure` setting.
    #
    # Subclasses own the service-specific address, stub class, timeout, metadata,
    # and error handling. This base holds only the transport that is identical
    # across IAM clients.
    class BaseClient
      LOGGED_INSECURE_ENDPOINTS = Concurrent::Set.new

      private

      def build_stub(stub_class, address, timeout:)
        stub_class.new(
          address,
          channel_credentials(address),
          interceptors: [
            Labkit::Correlation::GRPC::ClientInterceptor.instance,
            ServiceTokenInterceptor.build_from(service_token_credentials)
          ].compact,
          timeout: timeout
        )
      end

      # Subclasses must override this to return `{ header:, token: }`; every
      # RPC built via `build_stub` then carries it automatically. There is no
      # opt-out - every IAM gRPC client authenticates with a shared service
      # token, so a missing override is a bug, not a valid configuration.
      def service_token_credentials
        raise NotImplementedError, "#{self.class} must implement #service_token_credentials"
      end

      # Subclasses must override this to report their service's `secure` setting.
      def secure_transport?
        raise NotImplementedError, "#{self.class} must implement #secure_transport?"
      end

      def channel_credentials(address)
        return GRPC::Core::ChannelCredentials.new(::Gitlab::X509::Certificate.ca_certs_bundle) if secure_transport?

        log_insecure_channel(address)

        :this_channel_is_insecure
      end

      def log_insecure_channel(address)
        return unless LOGGED_INSECURE_ENDPOINTS.add?(address)

        Gitlab::AppLogger.info(
          message: 'Using an insecure IAM gRPC channel',
          Labkit::Fields::CLASS_NAME => self.class.name,
          address: address
        )
      end
    end
  end
end

# frozen_string_literal: true

module Authn
  module IamService
    # Shared transport for IAM gRPC clients. Builds a stub for a given service
    # and selects channel credentials from the address scheme (tls:// vs plaintext).
    #
    # Subclasses own the service-specific address, stub class, timeout, metadata,
    # and error handling. This base holds only the transport that is identical
    # across IAM clients.
    class BaseClient
      InsecureChannelError = Class.new(StandardError)

      private

      def build_stub(stub_class, address, timeout:)
        stub_class.new(
          strip_scheme(address),
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

      def channel_credentials(address)
        uri = URI(address)

        return GRPC::Core::ChannelCredentials.new(::Gitlab::X509::Certificate.ca_certs_bundle) if uri.scheme == 'tls'

        insecure_channel
      rescue URI::InvalidURIError
        insecure_channel
      end

      # A plaintext channel is only acceptable in development and test. Outside
      # those, refuse rather than silently talking to IAM without TLS.
      def insecure_channel
        unless Gitlab.dev_or_test_env?
          raise InsecureChannelError, 'Refusing to use an insecure IAM gRPC channel outside development and test'
        end

        :this_channel_is_insecure
      end

      def strip_scheme(address)
        address.sub(%r{^tcp://|^tls://}, '')
      end
    end
  end
end

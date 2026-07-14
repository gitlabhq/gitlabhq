# frozen_string_literal: true

module Authn
  module IamService
    # ServiceTokenInterceptor injects a shared service-token header into every
    # outbound call made through a client stub, so individual RPC methods
    # don't each need to remember to attach it. Mirrors the approach used by
    # Labkit::Correlation::GRPC::ClientInterceptor for correlation IDs.
    class ServiceTokenInterceptor < ::GRPC::ClientInterceptor
      # Builds an interceptor from a `{ header:, token: }` credentials hash, or
      # returns nil if credentials is nil. Lets callers do
      # `ServiceTokenInterceptor.build_from(service_token_credentials)` and
      # `.compact` the result into an interceptor list, without an
      # intermediate nil-check helper of their own.
      def self.build_from(credentials)
        return unless credentials

        new(**credentials)
      end

      def initialize(header:, token:)
        @header = header
        @token = token

        super()
      end

      %i[request_response client_streamer server_streamer bidi_streamer].each do |call_type|
        define_method(call_type) do |metadata:, **, &block|
          inject_service_token(metadata)

          block.call
        end
      end

      private

      def inject_service_token(metadata)
        metadata[@header] = @token
      end
    end
  end
end

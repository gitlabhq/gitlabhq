# frozen_string_literal: true

module Gitlab
  module Metrics
    module GitalyClientSlis
      include Gitlab::Metrics::SliConfig

      puma_enabled!
      sidekiq_enabled!

      # gRPC status codes that should not count as errors for this SLI. This is
      # based on `gitalyGRPCErrorRateIgnoredCodes` in the runbooks helper
      # `libsonnet/service-archetypes/helpers/gitaly.libsonnet`, which decides
      # what the server-side SLI counts as an error. Keep the two lists in sync.
      #
      # Note: unlike the runbooks list, this SLI does not ignore
      # `resource_exhausted` or `deadline_exceeded`. On the client side a `ResourceExhausted` means the call did not
      # succeed for the caller, so we count it as an error.
      #
      # Codes are matched against the snake_case names from
      # `Gitlab::Git::BaseError::GRPC_CODES`.
      IGNORED_CODES = %w[
        ok
        cancelled
        invalid_argument
        not_found
        already_exists
        permission_denied
        failed_precondition
        unauthenticated
      ].freeze

      class << self
        def initialize_slis!
          Gitlab::Metrics::Sli::ErrorRate.initialize_sli(:gitaly_client_calls, [])
        end

        def record_error_rate(storage:, error: nil)
          Gitlab::Metrics::Sli::ErrorRate[:gitaly_client_calls].increment(
            labels: { gitaly_node: node_label(storage) },
            error: error?(error)
          )
        end

        def node_label(storage)
          uri = URI(::Gitlab::GitalyClient.address(storage))

          uri.host.presence || storage
        rescue StandardError
          storage
        end

        def error?(error)
          return false if error.nil?
          return true unless error.is_a?(::GRPC::BadStatus)

          name = ::Gitlab::Git::BaseError::GRPC_CODES[error.code.to_s]

          IGNORED_CODES.exclude?(name)
        end
      end
    end
  end
end

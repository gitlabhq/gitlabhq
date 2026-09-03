# frozen_string_literal: true

module Gitlab
  module Metrics
    module OpenbaoClientSlis
      include Gitlab::Metrics::SliConfig

      puma_enabled!
      sidekiq_enabled!

      class << self
        def initialize_slis!
          Gitlab::Metrics::Sli::ErrorRate.initialize_sli(:openbao_client_calls, possible_labels)
        end

        def record_error_rate(operation:, error:)
          Gitlab::Metrics::Sli::ErrorRate[:openbao_client_calls].increment(
            labels: { operation: operation },
            error: error
          )
        end

        private

        def possible_labels
          ::Gitlab::Instrumentation::Openbao::ALL_OPERATIONS.map do |operation|
            { operation: operation }
          end
        end
      end
    end
  end
end

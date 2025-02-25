# frozen_string_literal: true

module Gitlab
  module Metrics
    module GlqlSlis
      include Gitlab::Metrics::SliConfig

      puma_enabled!

      class << self
        def initialize_slis!
          glql_labels = possible_glql_labels
          Gitlab::Metrics::Sli::Apdex.initialize_sli(:glql, glql_labels)
          Gitlab::Metrics::Sli::ErrorRate.initialize_sli(:glql, glql_labels)
        end

        def record_apdex(labels:, success:)
          Gitlab::Metrics::Sli::Apdex[:glql].increment(labels: labels, success: success)
        end

        def record_error(labels:, error:)
          Gitlab::Metrics::Sli::ErrorRate[:glql].increment(labels: labels, error: error)
        end

        private

        def possible_glql_labels
          return [] unless Gitlab::Metrics::Environment.api?

          ::Gitlab::Graphql::KnownOperations.default.operations.map do |op|
            {
              endpoint_id: op.to_caller_id,
              # We'll be able to correlate feature_category with https://gitlab.com/gitlab-org/gitlab/-/issues/328535
              feature_category: nil,
              query_urgency: op.query_urgency.name
            }
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module Gitlab
  module Metrics
    module GlqlSlis
      include Gitlab::Metrics::SliConfig

      puma_enabled!

      class << self
        ERROR_TYPES = [:query_aborted, :other, nil].freeze
        ENDPOINTS = ['Glql::BaseController#execute'].freeze
        FEATURE_CATEGORIES = [
          :code_review_workflow,
          :not_owned,
          :portfolio_management,
          :team_planning,
          :wiki
        ].freeze

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

          # This generates all possible label combinations for GLQL metrics
          # by taking the product of the error types, feature categories, and endpoints.
          combinations = ERROR_TYPES.product(FEATURE_CATEGORIES, ENDPOINTS)
          low_urgency = Gitlab::EndpointAttributes::Config::REQUEST_URGENCIES.fetch(:low).name

          combinations.map do |error_type, feature_category, endpoint_id|
            {
              query_urgency: low_urgency,
              error_type: error_type,
              feature_category: feature_category,
              endpoint_id: endpoint_id
            }
          end
        end
      end
    end
  end
end

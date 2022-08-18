# frozen_string_literal: true

module Gitlab
  module GlobalId
    module Deprecations
      # Contains the deprecations in place.
      # Example:
      #
      #   DEPRECATIONS = [
      #     Gitlab::Graphql::DeprecationsBase::NameDeprecation.new(old_name: 'PrometheusService', new_name: 'Integrations::Prometheus', milestone: '14.1')
      #   ].freeze
      DEPRECATIONS = [
        # This works around an accidentally released argument named as `"EEIterationID"` in 7000489db.
        Gitlab::Graphql::DeprecationsBase::NameDeprecation.new(
          old_name: 'EEIteration', new_name: 'Iteration', milestone: '13.3'
        ),
        Gitlab::Graphql::DeprecationsBase::NameDeprecation.new(
          old_name: 'PrometheusService', new_name: 'Integrations::Prometheus', milestone: '14.1'
        )
      ].freeze

      def self.map_graphql_name(model_name)
        Types::GlobalIDType.model_name_to_graphql_name(model_name)
      end

      include Gitlab::Graphql::DeprecationsBase
    end
  end
end

# frozen_string_literal: true

module Gitlab
  module GlobalId
    module Deprecations
      Deprecation = Struct.new(:old_model_name, :new_model_name, :milestone, keyword_init: true)

      # Contains the deprecations in place.
      # Example:
      #
      #   DEPRECATIONS = [
      #     Deprecation.new(old_model_name: 'PrometheusService', new_model_name: 'Integrations::Prometheus', milestone: '14.1')
      #   ].freeze
      DEPRECATIONS = [
        # This works around an accidentally released argument named as `"EEIterationID"` in 7000489db.
        Deprecation.new(old_model_name: 'EEIteration', new_model_name: 'Iteration', milestone: '13.3'),
        Deprecation.new(old_model_name: 'PrometheusService', new_model_name: 'Integrations::Prometheus', milestone: '14.1')
      ].freeze

      # Maps of the DEPRECATIONS Hash for quick access.
      OLD_NAME_MAP = DEPRECATIONS.index_by(&:old_model_name).freeze
      NEW_NAME_MAP = DEPRECATIONS.index_by(&:new_model_name).freeze
      OLD_GRAPHQL_NAME_MAP = DEPRECATIONS.index_by do |d|
        Types::GlobalIDType.model_name_to_graphql_name(d.old_model_name)
      end.freeze

      def self.deprecated?(old_model_name)
        OLD_NAME_MAP.key?(old_model_name)
      end

      def self.deprecation_for(old_model_name)
        OLD_NAME_MAP[old_model_name]
      end

      def self.deprecation_by(new_model_name)
        NEW_NAME_MAP[new_model_name]
      end

      # Returns the new `graphql_name` (Type#graphql_name) of a deprecated GID,
      # or the `graphql_name` argument given if no deprecation applies.
      def self.apply_to_graphql_name(graphql_name)
        return graphql_name unless deprecation = OLD_GRAPHQL_NAME_MAP[graphql_name]

        Types::GlobalIDType.model_name_to_graphql_name(deprecation.new_model_name)
      end
    end
  end
end

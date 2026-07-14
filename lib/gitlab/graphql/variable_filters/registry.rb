# frozen_string_literal: true

module Gitlab
  module Graphql
    module VariableFilters
      # Registry mapping GraphQL operation names to variable filter modules.
      # Each filter module must respond to `.filter(variables)`.
      #
      # Operation names are taken from the `.graphql` mutation files in
      # app/assets/javascripts -- Apollo sends them as `operationName` in the
      # request body, and graphql-ruby exposes them as `query.operation_name`.
      # Custom API clients that use a different operation name will not have
      # their variables filtered by this registry.
      #
      # To add a new filter:
      #   1. Create a module under Gitlab::Graphql::VariableFilters
      #   2. Implement `.filter(variables)` returning the sanitized hash
      #   3. Add an entry to OPERATION_FILTER_MAP below
      module Registry
        # Maps operation names to filter module constant names (strings).
        # Using strings defers constant resolution to call time, allowing
        # Zeitwerk to autoload filter files on demand.
        OPERATION_FILTER_MAP = {
          'createPipelineSchedule' => 'Gitlab::Graphql::VariableFilters::CiInputsFilter',
          'updatePipelineSchedule' => 'Gitlab::Graphql::VariableFilters::CiInputsFilter',
          'retryJobWithVariables' => 'Gitlab::Graphql::VariableFilters::CiInputsFilter',
          'playJobWithInputs' => 'Gitlab::Graphql::VariableFilters::CiInputsFilter',
          'internalPipelineCreate' => 'Gitlab::Graphql::VariableFilters::CiInputsFilter'
        }.freeze

        def self.filter_for(operation_name)
          const_name = OPERATION_FILTER_MAP[operation_name]
          const_name ? Object.const_get(const_name, false) : nil
        end

        def self.filter(variables, operation_name)
          filter_for(operation_name)&.filter(variables) || variables
        end
      end
    end
  end
end

# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class BaseIntegrationsMetric < DatabaseMetric
          # Usage Example
          #
          # class ActiveGroupIntegrationsMetric < BaseIntegrationsMetric
          #   operation :count
          #
          #   relation do |database_time_constraints|
          #     Integration.active.where.not(group: nil).where(type: integrations_name(options))
          #   end
          # end

          def self.integrations_name(options)
            Integration.integration_name_to_type(options[:type])
          end

          def initialize(metric_definition)
            super

            type = options[:type]

            return if type.in?(allowed_types)

            prefix = "Invalid type #{type}. " if type
            raise ArgumentError, "#{prefix}Type must be one of: #{allowed_types.join(', ')}"
          end

          private

          # Overridden in EE
          def allowed_types
            Integration.available_integration_names(include_dev: false, include_disabled: true)
          end
        end
      end
    end
  end
end

Gitlab::Usage::Metrics::Instrumentations::BaseIntegrationsMetric.prepend_mod

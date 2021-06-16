# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class GenericMetric < BaseMetric
          # Usage example
          #
          # class UuidMetric < GenericMetric
          #   value do
          #     Gitlab::CurrentSettings.uuid
          #   end
          # end
          class << self
            attr_reader :metric_operation
            @metric_operation = :alt

            def value(&block)
              @metric_value = block
            end

            attr_reader :metric_value
          end

          def value
            alt_usage_data do
              self.class.metric_value.call
            end
          end

          def suggested_name
            Gitlab::Usage::Metrics::NameSuggestion.for(
              self.class.metric_operation
            )
          end
        end
      end
    end
  end
end

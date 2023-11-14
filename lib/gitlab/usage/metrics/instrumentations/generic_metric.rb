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
          FALLBACK = -1

          class << self
            attr_reader :metric_value

            def fallback(custom_fallback = FALLBACK)
              return @metric_fallback if defined?(@metric_fallback)

              @metric_fallback = custom_fallback
            end

            def value(&block)
              @metric_value = block
            end
          end

          def initialize(metric_definition)
            super(metric_definition.reverse_merge(time_frame: 'none'))
          end

          def value
            alt_usage_data(fallback: self.class.fallback) do
              instance_eval(&self.class.metric_value)
            end
          end
        end
      end
    end
  end
end

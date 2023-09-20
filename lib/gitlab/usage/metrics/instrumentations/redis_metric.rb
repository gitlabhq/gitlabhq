# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        # Usage example
        #
        # In metric YAML definition:
        #
        # instrumentation_class: RedisMetric
        # options:
        #   event: pushes
        #   prefix: source_code
        #
        class RedisMetric < BaseMetric
          include Gitlab::UsageDataCounters::RedisCounter

          USAGE_PREFIX = "USAGE_"
          OPTIONS_PREFIX_KEY = :prefix

          def initialize(metric_definition)
            super

            validate_options!
          end

          def validate_options!
            raise ArgumentError, "'event' option is required" unless metric_event.present?
            raise ArgumentError, "'prefix' option is required" unless options.has_key?(OPTIONS_PREFIX_KEY)
          end

          def metric_event
            options[:event]
          end

          def prefix
            options[OPTIONS_PREFIX_KEY]
          end

          def include_usage_prefix?
            options.fetch(:include_usage_prefix, true)
          end

          def value
            redis_usage_data do
              total_count(redis_key)
            end
          end

          def redis_key
            key = metric_event.dup
            key.prepend("#{prefix}_") if prefix
            key.prepend(USAGE_PREFIX) if include_usage_prefix?
            key.upcase
          end
        end
      end
    end
  end
end

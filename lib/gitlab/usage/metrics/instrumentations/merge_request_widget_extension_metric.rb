# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        # Usage example
        #
        # In metric YAML definition:
        #
        # instrumentation_class: MergeRequestWidgetExtensionMetric
        # options:
        #   event: expand
        #   widget: terraform
        #
        class MergeRequestWidgetExtensionMetric < RedisMetric
          extend ::Gitlab::Utils::Override

          def validate_options!
            raise ArgumentError, "'event' option is required" unless metric_event.present?
            raise ArgumentError, "'widget' option is required" unless widget_name.present?
          end

          def widget_name
            options[:widget]
          end

          override :prefix
          def prefix
            'i_code_review_merge_request_widget'
          end

          private

          override :redis_key
          def redis_key
            "#{USAGE_PREFIX}#{prefix}_#{widget_name}_count_#{metric_event}".upcase
          end
        end
      end
    end
  end
end

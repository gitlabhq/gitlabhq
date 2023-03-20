# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountBulkImportsEntitiesMetric < DatabaseMetric
          operation :count

          def initialize(metric_definition)
            super

            if source_type.present? && !source_type.in?(allowed_source_types)
              raise ArgumentError, "source_type '#{source_type}' must be one of: #{allowed_source_types.join(', ')}"
            end
          end

          relation { ::BulkImports::Entity }

          private

          def relation
            scope = super
            scope = scope.where(source_type: source_type) if source_type.present?
            scope = scope.where(status: status) if status.present?
            scope = scope.where(has_failures: failures) if failures.present?
            scope
          end

          def source_type
            options[:source_type].to_s
          end

          def status
            options[:status]
          end

          def failures
            options[:has_failures].to_s
          end

          def allowed_source_types
            BulkImports::Entity.source_types.keys.map(&:to_s)
          end
        end
      end
    end
  end
end

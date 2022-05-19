# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountBulkImportsEntitiesMetric < DatabaseMetric
          operation :count

          def initialize(time_frame:, options: {})
            super

            if source_type.present? && !source_type.in?(allowed_source_types)
              raise ArgumentError, "source_type '#{source_type}' must be one of: #{allowed_source_types.join(', ')}"
            end
          end

          relation { ::BulkImports::Entity }

          private

          def relation
            return super.where(source_type: source_type) if source_type.present? # rubocop: disable CodeReuse/ActiveRecord

            super
          end

          def source_type
            options[:source_type].to_s
          end

          def allowed_source_types
            BulkImports::Entity.source_types.keys.map(&:to_s)
          end
        end
      end
    end
  end
end

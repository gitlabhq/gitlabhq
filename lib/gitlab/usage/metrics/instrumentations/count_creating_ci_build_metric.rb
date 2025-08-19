# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountCreatingCiBuildMetric < DatabaseMetric
          SECURE_PRODUCT_TYPES = %i[
            apifuzzer_fuzz
            apifuzzer_fuzz_dnd
            container_scanning
            coverage_fuzzing
            dast
            dependency_scanning
            license_management
            license_scanning
            sast
            secret_detection
          ].freeze

          def initialize(metric_definition)
            super

            raise ArgumentError, "secure_type options attribute is required" unless secure_type.present?
            return if secure_type_all? || SECURE_PRODUCT_TYPES.include?(secure_type)

            raise ArgumentError, "Attribute: #{secure_type} is not allowed"
          end

          private

          def relation
            secure_type_all? ? super.where(name: SECURE_PRODUCT_TYPES) : super.where(name: secure_type)
          end

          def secure_type
            options[:secure_type]&.to_sym
          end

          def secure_type_all?
            secure_type == :all
          end
        end
      end
    end
  end
end

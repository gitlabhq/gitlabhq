# frozen_string_literal: true

module Gitlab
  module GrapeOpenapi
    module Concerns
      module FailFastAnnotatable
        FAIL_FAST_ANNOTATION = '(validation stops on first error)'

        private

        def fail_fast_in_validations?(validations)
          validations&.any? { |v| v.dig(:opts, :fail_fast) }
        end

        def annotate_fail_fast(desc)
          return desc.to_s if desc.to_s.include?(FAIL_FAST_ANNOTATION)

          "#{desc} #{FAIL_FAST_ANNOTATION}"
        end
      end
    end
  end
end

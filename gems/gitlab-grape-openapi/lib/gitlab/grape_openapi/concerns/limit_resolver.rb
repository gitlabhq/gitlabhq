# frozen_string_literal: true

# API::Validations::Validators::Limit is a custom validator unique to GitLab.
# This resolver compares by class name string rather than constant reference so that this gem
# does not blow up in environments where the validator is not defined.

module Gitlab
  module GrapeOpenapi
    module Concerns
      module LimitResolver
        private

        def limit_for(validations)
          validation = validations&.find do |v|
            v[:validator_class].name == 'API::Validations::Validators::Limit'
          rescue NoMethodError
            false
          end
          validation && validation[:options]
        end

        def apply_limit!(schema, validations)
          return unless schema[:type] == 'string'

          limit = limit_for(validations)
          schema[:maxLength] = limit if limit.is_a?(Integer) && limit.positive?
        end
      end
    end
  end
end

# frozen_string_literal: true

module API
  module Validations
    module Validators
      class IntegerNoneAny < IntegerOrCustomValue
        private

        def extract_custom_values(options)
          [IssuableFinder::Params::FILTER_NONE, IssuableFinder::Params::FILTER_ANY]
        end
      end
    end
  end
end

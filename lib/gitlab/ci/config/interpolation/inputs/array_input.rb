# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Interpolation
        class Inputs
          class ArrayInput < BaseInput
            extend ::Gitlab::Utils::Override

            def self.type_name
              'array'
            end

            override :validate_type
            def validate_type(value, default)
              return if value.is_a?(Array)

              error("#{default ? 'default' : 'provided'} value is not an array")
            end
          end
        end
      end
    end
  end
end

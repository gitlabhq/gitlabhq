# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Interpolation
        class Inputs
          class BooleanInput < BaseInput
            extend ::Gitlab::Utils::Override

            def self.type_name
              'boolean'
            end

            override :validate_type
            def validate_type(value, default)
              return if [true, false].include?(value)

              error("#{default ? 'default' : 'provided'} value is not a boolean")
            end
          end
        end
      end
    end
  end
end

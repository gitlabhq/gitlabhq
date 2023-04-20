# frozen_string_literal: true

module Gitlab
  module Ci
    module Input
      module Arguments
        ##
        # Input::Arguments::Default class represents user-provided input argument that has a default value.
        #
        class Default < Input::Arguments::Base
          def validate!
            return error('argument specification invalid') unless spec.key?(:default)

            error('invalid default value') unless default.is_a?(String) || default.nil?
          end

          ##
          # User-provided value needs to be specified, but it may be an empty string:
          #
          # ```yaml
          # inputs:
          #   env:
          #     default: development
          #
          # with:
          #   env: ""
          # ```
          #
          # The configuration above will result in `env` being an empty string.
          #
          def to_value
            value.nil? ? default : value
          end

          def default
            spec[:default]
          end

          def self.matches?(spec)
            return false unless spec.is_a?(Hash)

            spec.count == 1 && spec.each_key.first == :default
          end
        end
      end
    end
  end
end

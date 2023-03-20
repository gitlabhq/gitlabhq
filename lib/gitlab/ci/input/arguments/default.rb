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
            error('invalid specification') unless default.present?
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
            spec.count == 1 && spec.each_key.first == :default
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module Gitlab
  module Ci
    module Input
      module Arguments
        ##
        # Input::Arguments::Required class represents user-provided required input argument.
        #
        class Required < Input::Arguments::Base
          ##
          # The value has to be defined, but it may be empty.
          #
          def validate!
            error('required value has not been provided') if value.nil?
          end

          def to_value
            value
          end

          ##
          # Required arguments do not have nested configuration. It has to be defined a null value.
          #
          # ```yaml
          #   spec:
          #     inputs:
          #       website:
          # ```
          #
          # An empty string value, that has no specification is also considered as a "required" input, however we should
          # never see that being used, because it will be rejected by Ci::Config::Header validation.
          #
          # ```yaml
          #   spec:
          #     inputs:
          #       website: ""
          # ```
          #
          # An empty hash value is also considered to be a required argument:
          #
          # ```yaml
          #   spec:
          #     inputs:
          #       website: {}
          # ```
          #
          def self.matches?(spec)
            spec.blank?
          end
        end
      end
    end
  end
end

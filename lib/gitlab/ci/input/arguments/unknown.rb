# frozen_string_literal: true

module Gitlab
  module Ci
    module Input
      module Arguments
        ##
        # Input::Arguments::Unknown object gets fabricated when we can't match an input argument entry with any known
        # specification. It is matched as the last one, and always returns an error.
        #
        class Unknown < Input::Arguments::Base
          def validate!
            if spec.is_a?(Hash) && spec.count == 1
              error("unrecognized input argument specification: `#{spec.each_key.first}`")
            else
              error('unrecognized input argument definition')
            end
          end

          def to_value
            raise ArgumentError, 'unknown argument value'
          end

          def self.matches?(*)
            true
          end
        end
      end
    end
  end
end

module Gitlab
  module Ci
    class Config
      module Node
        ##
        # This class represents an undefined and unspecified node.
        #
        # Implements the Null Object pattern.
        #
        class Null < Entry
          def initialize(config = nil, **attributes)
            super
          end

          def value
            nil
          end

          def valid?
            true
          end

          def errors
            []
          end
        end
      end
    end
  end
end

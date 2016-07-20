module Gitlab
  module Ci
    class Config
      module Node
        ##
        # This class represents an undefined and unspecified entry node.
        #
        # It decorates original entry adding method that indicates it is
        # unspecified.
        #
        class Undefined < SimpleDelegator
          def initialize(entry)
            super
          end

          def specified?
            false
          end
        end
      end
    end
  end
end

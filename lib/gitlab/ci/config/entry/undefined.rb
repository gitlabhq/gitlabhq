module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # This class represents an undefined entry.
        #
        class Undefined < Node
          def initialize(*)
            super(nil)
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

          def specified?
            false
          end

          def relevant?
            false
          end
        end
      end
    end
  end
end

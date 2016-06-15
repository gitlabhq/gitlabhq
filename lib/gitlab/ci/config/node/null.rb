module Gitlab
  module Ci
    class Config
      module Node
        ##
        # This class represents a configuration entry that is not being used
        # in configuration file.
        #
        # This implements Null Object pattern.
        #
        class Null < Entry
          def value
            nil
          end

          def validate!
            nil
          end

          def method_missing(*)
            nil
          end
        end
      end
    end
  end
end

module Gitlab
  module Ci
    class Config
      ##
      # This class represents a configuration entry that is not being used
      # in configuration file.
      #
      # This implements Null Object pattern.
      #
      module Node
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

module Gitlab
  module Ci
    class Config
      module Node
        ##
        # This class represents a configuration entry that is not defined
        # in configuration file.
        #
        # This implements a Null Object pattern.
        #
        # It can be initialized using a default value of entry that is not
        # present in configuration.
        #
        class Undefined < Entry
          def method_missing(*)
            nil
          end
        end
      end
    end
  end
end

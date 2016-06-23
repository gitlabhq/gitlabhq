module Gitlab
  module Ci
    class Config
      module Node
        ##
        # This class represents an undefined entry node.
        #
        # It takes original entry class as configuration and returns default
        # value of original entry as self value.
        #
        #
        class Undefined < Entry
          include Validatable

          validations do
            validates :config, type: Class
          end

          def value
            @config.default
          end

          def defined?
            false
          end
        end
      end
    end
  end
end

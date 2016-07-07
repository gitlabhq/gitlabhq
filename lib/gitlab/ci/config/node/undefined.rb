module Gitlab
  module Ci
    class Config
      module Node
        ##
        # This class represents an undefined entry node.
        #
        # It takes original entry class as configuration and creates an object
        # if original entry has a default value. If there is default value
        # some methods are delegated to it.
        #
        #
        class Undefined < Entry
          include Validatable

          validations do
            validates :config, type: Class
          end

          def initialize(node)
            super

            unless node.default.nil?
              @default = fabricate_default(node)
            end
          end

          def value
            @default.value if @default
          end

          def valid?
            @default ? @default.valid? : true
          end

          def errors
            @default ? @default.errors : []
          end

          def defined?
            false
          end

          private

          def fabricate_default(node)
            Node::Factory.fabricate(node, node.default, attributes)
          end
        end
      end
    end
  end
end

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

          delegate :valid?, :errors, :value, to: :@strategy

          validations do
            validates :config, type: Class
          end

          def initialize(node)
            super
            @strategy = create_strategy(node, node.default)
          end

          def defined?
            false
          end

          private

          def create_strategy(node, default)
            if default.nil?
              Undefined::NullStrategy.new
            else
              entry = Node::Factory
                .fabricate(node, default, attributes)

              Undefined::DefaultStrategy.new(entry)
            end
          end

          class DefaultStrategy
            delegate :valid?, :errors, :value, to: :@default

            def initialize(entry)
              @default = entry
            end
          end

          class NullStrategy
            def initialize(*)
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
end

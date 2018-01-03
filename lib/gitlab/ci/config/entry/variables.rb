module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents environment variables.
        #
        class Variables < Node
          include Validatable

          validations do
            validates :config, variables: true
          end

          def self.default
            {}
          end

          def value
            Hash[@config.map { |key, value| [key.to_s, value.to_s] }]
          end
        end
      end
    end
  end
end

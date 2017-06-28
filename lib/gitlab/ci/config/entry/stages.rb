module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a configuration for pipeline stages.
        #
        class Stages < Node
          include Validatable

          validations do
            validates :config, array_of_strings: true
          end

          def self.default
            %w[build test deploy]
          end
        end
      end
    end
  end
end

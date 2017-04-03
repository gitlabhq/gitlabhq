module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a key.
        #
        class Key < Node
          include Validatable

          validations do
            validates :config, key: true
          end

          def self.default
            'default'
          end
        end
      end
    end
  end
end

module Gitlab
  module Ci
    class Config
      module Node
        ##
        # Entry that represents a key.
        #
        class Key < Entry
          include Validatable

          validations do
            validates :config, key: true
          end
        end
      end
    end
  end
end

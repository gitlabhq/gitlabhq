module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a boolean value.
        #
        class Boolean < Node
          include Validatable

          validations do
            validates :config, boolean: true
          end
        end
      end
    end
  end
end

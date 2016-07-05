module Gitlab
  module Ci
    class Config
      module Node
        ##
        # Entry that represents a boolean value.
        #
        class Boolean < Entry
          include Validatable

          validations do
            validates :config, boolean: true
          end
        end
      end
    end
  end
end

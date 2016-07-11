module Gitlab
  module Ci
    class Config
      module Node
        ##
        # Entry that represents a script.
        #
        class Script < Entry
          include Validatable

          validations do
            validates :config, array_of_strings: true
          end
        end
      end
    end
  end
end

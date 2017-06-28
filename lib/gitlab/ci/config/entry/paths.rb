module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents an array of paths.
        #
        class Paths < Node
          include Validatable

          validations do
            validates :config, array_of_strings: true
          end
        end
      end
    end
  end
end

module Gitlab
  module Ci
    class Config
      module Node
        ##
        # Entry that represents an array of paths.
        #
        class Paths < Entry
          include Validatable

          validations do
            validates :config, array_of_strings: true
          end
        end
      end
    end
  end
end

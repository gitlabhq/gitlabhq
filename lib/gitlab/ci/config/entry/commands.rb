module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a job script.
        #
        class Commands < Node
          include Validatable

          validations do
            validates :config, array_of_strings_or_string: true
          end

          def value
            Array(@config)
          end
        end
      end
    end
  end
end

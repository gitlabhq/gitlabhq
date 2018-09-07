module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a Docker image.
        #
        class Includes < Node
          include Validatable

          validations do
            validates :config, array_or_string: true, external_file: true, allow_nil: true
          end

          def value
            Array(@config)
          end
        end
      end
    end
  end
end

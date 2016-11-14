module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a configuration of Docker services.
        #
        class Services < Node
          include Validatable

          validations do
            validates :config, array_of_strings: true
          end
        end
      end
    end
  end
end

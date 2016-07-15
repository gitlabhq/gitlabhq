module Gitlab
  module Ci
    class Config
      module Node
        ##
        # Entry that represents a configuration of Docker services.
        #
        class Services < Entry
          include Validatable

          validations do
            validates :config, array_of_strings: true
          end
        end
      end
    end
  end
end

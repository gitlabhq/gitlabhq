module Gitlab
  module Ci
    class Config
      module Node
        ##
        # Entry that represents environment variables.
        #
        class Variables < Entry
          include Validatable

          validations do
            validates :config, variables: true
          end

          def self.default
            {}
          end
        end
      end
    end
  end
end

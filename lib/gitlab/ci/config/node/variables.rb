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
            validates :value, variables: true
          end

          def value
            @config || self.class.default
          end

          def self.default
            {}
          end
        end
      end
    end
  end
end

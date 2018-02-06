module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a hidden CI/CD key.
        #
        class Hidden < Node
          include Validatable

          validations do
            validates :config, presence: true
          end

          def relevant?
            false
          end
        end
      end
    end
  end
end

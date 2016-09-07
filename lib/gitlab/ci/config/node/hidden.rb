module Gitlab
  module Ci
    class Config
      module Node
        ##
        # Entry that represents a hidden CI/CD job.
        #
        class Hidden < Entry
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

module Gitlab
  module Ci
    class Config
      module Node
        ##
        # Entry that represents a stage for a job.
        #
        class Stage < Entry
          include Validatable

          validations do
            validates :config, type: String
          end

          def self.default
            'test'
          end
        end
      end
    end
  end
end

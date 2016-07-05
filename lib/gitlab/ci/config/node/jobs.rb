module Gitlab
  module Ci
    class Config
      module Node
        ##
        # Entry that represents a set of jobs.
        #
        class Jobs < Entry
          include Validatable

          validations do
            validates :config, type: Hash
          end
        end
      end
    end
  end
end

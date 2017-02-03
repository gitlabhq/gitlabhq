module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a trigger policy for the job.
        #
        class Trigger < Node
          include Validatable

          validations do
            validates :config, array_of_strings_or_regexps: true
          end
        end
      end
    end
  end
end

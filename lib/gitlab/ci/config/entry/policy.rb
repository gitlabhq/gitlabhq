module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a trigger policy for the job.
        #
        class Policy < Simplifiable
          strategy :RefsPolicy, if: -> (config) { config.is_a?(Array) }
          strategy :ExpressionsPolicy, if: -> (config) { config.is_a?(Hash) }

          class RefsPolicy < Entry::Node
            include Entry::Validatable

            validations do
              validates :config, array_of_strings_or_regexps: true
            end

            def value
              { refs: @config }
            end
          end

          class ExpressionsPolicy < Entry::Node
            include Entry::Validatable

            validations do
              validates :config, type: Hash
            end
          end
        end
      end
    end
  end
end

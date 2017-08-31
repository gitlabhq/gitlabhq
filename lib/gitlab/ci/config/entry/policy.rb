module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents an only/except trigger policy for the job.
        #
        class Policy < Simplifiable
          strategy :RefsPolicy, if: -> (config) { config.is_a?(Array) }

          class RefsPolicy < Entry::Node
            include Entry::Validatable

            validations do
              validates :config, array_of_strings_or_regexps: true
            end
          end

          class UnknownStrategy < Entry::Node
            def errors
              ["#{location} has to be either an array of conditions or a hash"]
            end
          end

          def self.default
          end
        end
      end
    end
  end
end

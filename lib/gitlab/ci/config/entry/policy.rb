module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents an only/except trigger policy for the job.
        #
        class Policy < Simplifiable
          strategy :RefsPolicy, if: -> (config) { config.is_a?(Array) }
          strategy :ExpressionsPolicy, if: -> (config) { config.is_a?(Hash) }

          class RefsPolicy < Entry::Node
            include Entry::Validatable

            validations do
              validates :config, array_of_strings_or_regexps: true
            end
          end

          class ExpressionsPolicy < Entry::Node
            include Entry::Validatable
            include Entry::Attributable

            attributes :refs, :expressions

            validations do
              validates :config, presence: true
              validates :config, allowed_keys: %i[refs expressions]

              with_options allow_nil: true do
                validates :refs, array_of_strings_or_regexps: true
                validates :expressions, type: Array
                validates :expressions, presence: true
              end
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

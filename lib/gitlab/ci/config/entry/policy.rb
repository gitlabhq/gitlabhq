module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents an only/except trigger policy for the job.
        #
        class Policy < Simplifiable
          strategy :RefsPolicy, if: -> (config) { config.is_a?(Array) }
          strategy :ComplexPolicy, if: -> (config) { config.is_a?(Hash) }

          class RefsPolicy < Entry::Node
            include Entry::Validatable

            validations do
              validates :config, array_of_strings_or_regexps: true
            end

            def value
              { refs: @config }
            end
          end

          class ComplexPolicy < Entry::Node
            include Entry::Validatable
            include Entry::Attributable

            attributes :refs, :kubernetes

            validations do
              validates :config, presence: true
              validates :config, allowed_keys: %i[refs kubernetes]

              with_options allow_nil: true do
                validates :refs, array_of_strings_or_regexps: true
                validates :kubernetes, allowed_values: %w[active]
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

# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        class Need < ::Gitlab::Config::Entry::Simplifiable
          strategy :Job, if: -> (config) { config.is_a?(String) }

          class Job < ::Gitlab::Config::Entry::Node
            include ::Gitlab::Config::Entry::Validatable

            validations do
              validates :config, presence: true
              validates :config, type: String
            end

            def type
              :job
            end

            def value
              { name: @config }
            end
          end

          class UnknownStrategy < ::Gitlab::Config::Entry::Node
            def type
            end

            def value
            end

            def errors
              ["#{location} has an unsupported type"]
            end
          end
        end
      end
    end
  end
end

::Gitlab::Ci::Config::Entry::Need.prepend_if_ee('::EE::Gitlab::Ci::Config::Entry::Need')

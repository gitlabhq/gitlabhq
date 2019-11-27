# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        class Need < ::Gitlab::Config::Entry::Simplifiable
          strategy :JobString, if: -> (config) { config.is_a?(String) }
          strategy :JobHash, if: -> (config) { config.is_a?(Hash) && config.key?(:job) }

          class JobString < ::Gitlab::Config::Entry::Node
            include ::Gitlab::Config::Entry::Validatable

            validations do
              validates :config, presence: true
              validates :config, type: String
            end

            def type
              :job
            end

            def value
              { name: @config, artifacts: true }
            end
          end

          class JobHash < ::Gitlab::Config::Entry::Node
            include ::Gitlab::Config::Entry::Validatable
            include ::Gitlab::Config::Entry::Attributable

            ALLOWED_KEYS = %i[job artifacts].freeze
            attributes :job, :artifacts

            validations do
              validates :config, presence: true
              validates :config, allowed_keys: ALLOWED_KEYS
              validates :job, type: String, presence: true
              validates :artifacts, boolean: true, allow_nil: true
            end

            def type
              :job
            end

            def value
              { name: job, artifacts: artifacts || artifacts.nil? }
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

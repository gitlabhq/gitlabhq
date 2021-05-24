# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        class Need < ::Gitlab::Config::Entry::Simplifiable
          strategy :JobString, if: -> (config) { config.is_a?(String) }

          strategy :JobHash,
            if: -> (config) { config.is_a?(Hash) && same_pipeline_need?(config) }

          strategy :CrossPipelineDependency,
            if: -> (config) { config.is_a?(Hash) && cross_pipeline_need?(config) }

          def self.same_pipeline_need?(config)
            config.key?(:job) &&
              !(config.key?(:project) || config.key?(:ref) || config.key?(:pipeline))
          end

          def self.cross_pipeline_need?(config)
            config.key?(:job) && config.key?(:pipeline) && !config.key?(:project)
          end

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
              { name: @config,
                artifacts: true,
                optional: false }
            end
          end

          class JobHash < ::Gitlab::Config::Entry::Node
            include ::Gitlab::Config::Entry::Validatable
            include ::Gitlab::Config::Entry::Attributable

            ALLOWED_KEYS = %i[job artifacts optional].freeze
            attributes :job, :artifacts, :optional

            validations do
              validates :config, presence: true
              validates :config, allowed_keys: ALLOWED_KEYS
              validates :job, type: String, presence: true
              validates :artifacts, boolean: true, allow_nil: true
              validates :optional, boolean: true, allow_nil: true
            end

            def type
              :job
            end

            def value
              { name: job,
                artifacts: artifacts || artifacts.nil?,
                optional: !!optional }
            end
          end

          class CrossPipelineDependency < ::Gitlab::Config::Entry::Node
            include ::Gitlab::Config::Entry::Validatable
            include ::Gitlab::Config::Entry::Attributable

            ALLOWED_KEYS = %i[pipeline job artifacts].freeze
            attributes :pipeline, :job, :artifacts

            validations do
              validates :config, presence: true
              validates :config, allowed_keys: ALLOWED_KEYS
              validates :pipeline, type: String, presence: true
              validates :job, type: String, presence: true
              validates :artifacts, boolean: true, allow_nil: true
            end

            def type
              :cross_dependency
            end

            def value
              super.merge(artifacts: artifacts || artifacts.nil?)
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

::Gitlab::Ci::Config::Entry::Need.prepend_mod_with('Gitlab::Ci::Config::Entry::Need')

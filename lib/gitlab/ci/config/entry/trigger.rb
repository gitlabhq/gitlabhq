# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a parent-child or cross-project downstream trigger.
        #
        class Trigger < ::Gitlab::Config::Entry::Simplifiable
          strategy :SimpleTrigger, if: ->(config) { config.is_a?(String) }
          strategy :ComplexTrigger, if: ->(config) { config.is_a?(Hash) }

          # cross-project
          class SimpleTrigger < ::Gitlab::Config::Entry::Node
            include ::Gitlab::Config::Entry::Validatable

            validations { validates :config, presence: true }

            def value
              { project: @config }
            end
          end

          class ComplexTrigger < ::Gitlab::Config::Entry::Simplifiable
            strategy :CrossProjectTrigger, if: ->(config) { !config.key?(:include) }

            strategy :SameProjectTrigger, if: ->(config) do
              config.key?(:include)
            end

            # cross-project
            class CrossProjectTrigger < ::Gitlab::Config::Entry::Node
              include ::Gitlab::Config::Entry::Validatable
              include ::Gitlab::Config::Entry::Attributable
              include ::Gitlab::Config::Entry::Configurable

              ALLOWED_KEYS = %i[project branch strategy forward].freeze
              attributes :project, :branch, :strategy

              validations do
                validates :config, presence: true
                validates :config, allowed_keys: ALLOWED_KEYS
                validates :project, type: String, presence: true
                validates :branch, type: String, allow_nil: true
                validates :strategy, type: String, inclusion: { in: %w[depend], message: 'should be depend' }, allow_nil: true
              end

              entry :forward, ::Gitlab::Ci::Config::Entry::Trigger::Forward,
                description: 'List what to forward to downstream pipelines'

              def value
                { project: project,
                  branch: branch,
                  strategy: strategy,
                  forward: forward_value }.compact
              end
            end

            # parent-child
            class SameProjectTrigger < ::Gitlab::Config::Entry::Node
              include ::Gitlab::Config::Entry::Validatable
              include ::Gitlab::Config::Entry::Attributable
              include ::Gitlab::Config::Entry::Configurable

              INCLUDE_MAX_SIZE = 3
              ALLOWED_KEYS = %i[strategy include forward].freeze
              attributes :strategy

              validations do
                validates :config, presence: true
                validates :config, allowed_keys: ALLOWED_KEYS
                validates :strategy, type: String, inclusion: { in: %w[depend], message: 'should be depend' }, allow_nil: true
              end

              entry :include, ::Gitlab::Ci::Config::Entry::Includes,
                description: 'List of external YAML files to include.',
                reserved: true,
                metadata: { max_size: INCLUDE_MAX_SIZE }

              entry :forward, ::Gitlab::Ci::Config::Entry::Trigger::Forward,
                description: 'List what to forward to downstream pipelines'

              def value
                { include: @config[:include],
                  strategy: strategy,
                  forward: forward_value }.compact
              end
            end

            class UnknownStrategy < ::Gitlab::Config::Entry::Node
              def errors
                ['config must specify either project or include']
              end
            end
          end

          class UnknownStrategy < ::Gitlab::Config::Entry::Node
            def errors
              ["#{location} has to be either a string or a hash"]
            end
          end
        end
      end
    end
  end
end

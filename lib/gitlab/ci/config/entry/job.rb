# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a concrete CI/CD job.
        #
        class Job < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Configurable
          include ::Gitlab::Config::Entry::Attributable
          include ::Gitlab::Config::Entry::Inheritable

          ALLOWED_WHEN = %w[on_success on_failure always manual delayed].freeze
          ALLOWED_KEYS = %i[tags script only except rules type image services
                            allow_failure type stage when start_in artifacts cache
                            dependencies before_script needs after_script variables
                            environment coverage retry parallel extends interruptible timeout].freeze

          REQUIRED_BY_NEEDS = %i[stage].freeze

          validations do
            validates :config, type: Hash
            validates :config, allowed_keys: ALLOWED_KEYS
            validates :config, required_keys: REQUIRED_BY_NEEDS, if: :has_needs?
            validates :config, presence: true
            validates :script, presence: true
            validates :name, presence: true
            validates :name, type: Symbol
            validates :config,
              disallowed_keys: {
                in: %i[only except when start_in],
                message: 'key may not be used with `rules`'
              },
              if: :has_rules?

            with_options allow_nil: true do
              validates :tags, array_of_strings: true
              validates :allow_failure, boolean: true
              validates :parallel, numericality: { only_integer: true,
                                                   greater_than_or_equal_to: 2,
                                                   less_than_or_equal_to: 50 }
              validates :when, inclusion: {
                in: ALLOWED_WHEN,
                message: "should be one of: #{ALLOWED_WHEN.join(', ')}"
              }

              validates :dependencies, array_of_strings: true
              validates :extends, array_of_strings_or_string: true
              validates :rules, array_of_hashes: true
            end

            validates :start_in, duration: { limit: '1 week' }, if: :delayed?
            validates :start_in, absence: true, if: -> { has_rules? || !delayed? }

            validate do
              next unless dependencies.present?
              next unless needs.present?

              missing_needs = dependencies - needs
              if missing_needs.any?
                errors.add(:dependencies, "the #{missing_needs.join(", ")} should be part of needs")
              end
            end
          end

          entry :before_script, Entry::Script,
            description: 'Global before script overridden in this job.',
            inherit: true

          entry :script, Entry::Commands,
            description: 'Commands that will be executed in this job.',
            inherit: false

          entry :stage, Entry::Stage,
            description: 'Pipeline stage this job will be executed into.',
            inherit: false

          entry :type, Entry::Stage,
            description: 'Deprecated: stage this job will be executed into.',
            inherit: false

          entry :after_script, Entry::Script,
            description: 'Commands that will be executed when finishing job.',
            inherit: true

          entry :cache, Entry::Cache,
            description: 'Cache definition for this job.',
            inherit: true

          entry :image, Entry::Image,
            description: 'Image that will be used to execute this job.',
            inherit: true

          entry :services, Entry::Services,
            description: 'Services that will be used to execute this job.',
            inherit: true

          entry :interruptible, Entry::Boolean,
            description: 'Set jobs interruptible value.',
            inherit: true

          entry :timeout, Entry::Timeout,
            description: 'Timeout duration of this job.',
            inherit: true

          entry :retry, Entry::Retry,
            description: 'Retry configuration for this job.',
            inherit: true

          entry :only, Entry::Policy,
            description: 'Refs policy this job will be executed for.',
            default: Entry::Policy::DEFAULT_ONLY,
            inherit: false

          entry :except, Entry::Policy,
            description: 'Refs policy this job will be executed for.',
            inherit: false

          entry :rules, Entry::Rules,
            description: 'List of evaluable Rules to determine job inclusion.',
            inherit: false,
            metadata: {
              allowed_when: %w[on_success on_failure always never manual delayed].freeze
            }

          entry :needs, Entry::Needs,
            description: 'Needs configuration for this job.',
            metadata: { allowed_needs: %i[job] },
            inherit: false

          entry :variables, Entry::Variables,
            description: 'Environment variables available for this job.',
            inherit: false

          entry :artifacts, Entry::Artifacts,
            description: 'Artifacts configuration for this job.',
            inherit: false

          entry :environment, Entry::Environment,
            description: 'Environment configuration for this job.',
            inherit: false

          entry :coverage, Entry::Coverage,
            description: 'Coverage configuration for this job.',
            inherit: false

          helpers :before_script, :script, :stage, :type, :after_script,
                  :cache, :image, :services, :only, :except, :variables,
                  :artifacts, :environment, :coverage, :retry, :rules,
                  :parallel, :needs, :interruptible

          attributes :script, :tags, :allow_failure, :when, :dependencies,
                     :needs, :retry, :parallel, :extends, :start_in, :rules,
                     :interruptible, :timeout

          def self.matching?(name, config)
            !name.to_s.start_with?('.') &&
              config.is_a?(Hash) && config.key?(:script)
          end

          def self.visible?
            true
          end

          def compose!(deps = nil)
            super do
              if type_defined? && !stage_defined?
                @entries[:stage] = @entries[:type]
              end

              @entries.delete(:type)

              # This is something of a hack, see issue for details:
              # https://gitlab.com/gitlab-org/gitlab/issues/31685
              if !only_defined? && has_rules?
                @entries.delete(:only)
                @entries.delete(:except)
              end
            end
          end

          def name
            @metadata[:name]
          end

          def value
            @config.merge(to_hash.compact)
          end

          def manual_action?
            self.when == 'manual'
          end

          def delayed?
            self.when == 'delayed'
          end

          def has_rules?
            @config.try(:key?, :rules)
          end

          def ignored?
            allow_failure.nil? ? manual_action? : allow_failure
          end

          private

          def overwrite_entry(deps, key, current_entry)
            deps.default[key] unless current_entry.specified?
          end

          def to_hash
            { name: name,
              before_script: before_script_value,
              script: script_value,
              image: image_value,
              services: services_value,
              stage: stage_value,
              cache: cache_value,
              only: only_value,
              except: except_value,
              rules: has_rules? ? rules_value : nil,
              variables: variables_defined? ? variables_value : {},
              environment: environment_defined? ? environment_value : nil,
              environment_name: environment_defined? ? environment_value[:name] : nil,
              coverage: coverage_defined? ? coverage_value : nil,
              retry: retry_defined? ? retry_value : nil,
              parallel: parallel_defined? ? parallel_value.to_i : nil,
              interruptible: interruptible_defined? ? interruptible_value : nil,
              timeout: has_timeout? ? ChronicDuration.parse(timeout.to_s) : nil,
              artifacts: artifacts_value,
              after_script: after_script_value,
              ignore: ignored?,
              needs: needs_defined? ? needs_value : nil }
          end
        end
      end
    end
  end
end

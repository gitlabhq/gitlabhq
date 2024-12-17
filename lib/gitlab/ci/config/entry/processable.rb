# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a CI/CD Processable (a job)
        #
        module Processable
          extend ActiveSupport::Concern

          include ::Gitlab::Config::Entry::Configurable
          include ::Gitlab::Config::Entry::Attributable
          include ::Gitlab::Config::Entry::Inheritable

          PROCESSABLE_ALLOWED_KEYS = %i[extends stage only except rules variables
                                        inherit allow_failure when needs resource_group environment
                                        interruptible].freeze
          MAX_NESTING_LEVEL = 10

          included do
            validations do
              validates :config, presence: true
              validates :name, presence: true
              validates :name, type: Symbol
              validates :name, length: { maximum: 255 }

              validates :config, mutually_exclusive_keys: %i[script trigger]
              validates :config, mutually_exclusive_keys: %i[run trigger]

              validates :config, disallowed_keys: {
                  in: %i[only except start_in],
                  message: 'key may not be used with `rules`',
                  ignore_nil: true
                }, if: :has_rules_value?

              with_options allow_nil: true do
                validates :extends, array_of_strings_or_string: true
                validates :rules, nested_array_of_hashes_or_arrays: { max_level: MAX_NESTING_LEVEL }
                validates :resource_group, type: String
              end
            end

            entry :stage, Entry::Stage,
              description: 'Pipeline stage this job will be executed into.',
              inherit: false

            entry :only, ::Gitlab::Ci::Config::Entry::Policy,
              description: 'Refs policy this job will be executed for.',
              default: ::Gitlab::Ci::Config::Entry::Policy::DEFAULT_ONLY,
              inherit: false

            entry :except, ::Gitlab::Ci::Config::Entry::Policy,
              description: 'Refs policy this job will be executed for.',
              inherit: false

            entry :rules, ::Gitlab::Ci::Config::Entry::Rules,
              description: 'List of evaluable Rules to determine job inclusion.',
              inherit: false,
              metadata: {
                allowed_when: %w[on_success on_failure always never manual delayed].freeze,
                allowed_keys: %i[if changes exists when start_in allow_failure variables needs interruptible].freeze
              }

            entry :variables, ::Gitlab::Ci::Config::Entry::Variables,
              description: 'Environment variables available for this job.',
              metadata: { allowed_value_data: %i[value expand] },
              inherit: false

            entry :inherit, ::Gitlab::Ci::Config::Entry::Inherit,
              description: 'Indicates whether to inherit defaults or not.',
              inherit: false,
              default: {}

            entry :environment, Entry::Environment,
              description: 'Environment configuration for this job.',
              inherit: false

            entry :interruptible, ::Gitlab::Config::Entry::Boolean,
              description: 'Set jobs interruptible value.',
              inherit: true

            attributes :extends, :rules, :resource_group
          end

          def compose!(deps = nil)
            has_workflow_rules = deps&.workflow_entry&.has_rules?

            super do
              # If workflow:rules: or rules: are used
              # they are considered not compatible
              # with `only/except` defaults
              #
              # Context: https://gitlab.com/gitlab-org/gitlab/merge_requests/21742
              if has_rules? || has_workflow_rules
                # Remove only/except defaults
                # defaults are not considered as defined
                @entries.delete(:only) unless only_defined? # rubocop:disable Gitlab/ModuleWithInstanceVariables
                @entries.delete(:except) unless except_defined? # rubocop:disable Gitlab/ModuleWithInstanceVariables
              end

              yield if block_given?
            end

            validate_against_warnings unless has_workflow_rules
          end

          def validate_against_warnings
            # If rules are valid format and workflow rules are not specified
            return unless rules_value

            last_rule = rules_value.last

            if last_rule&.keys == [:when] && last_rule[:when] != 'never'
              docs_url = 'read more: https://docs.gitlab.com/ee/ci/jobs/job_troubleshooting.html#job-may-allow-multiple-pipelines-to-run-for-a-single-action-warning'
              add_warning("may allow multiple pipelines to run for a single action due to `rules:when` clause with no `workflow:rules` - #{docs_url}")
            end
          end

          def name
            metadata[:name]
          end

          def overwrite_entry(deps, key, current_entry)
            return unless inherit_entry&.default_entry&.inherit?(key)
            return unless deps.default_entry

            deps.default_entry[key] unless current_entry.specified?
          end

          def value
            { name: name,
              stage: stage_value,
              extends: extends,
              rules: rules_value,
              job_variables: variables_entry.value_with_data,
              root_variables_inheritance: root_variables_inheritance,
              only: only_value,
              except: except_value,
              environment: environment_defined? ? environment_value : nil,
              environment_name: environment_defined? ? environment_value[:name] : nil,
              resource_group: resource_group,
              interruptible: interruptible_defined? ? interruptible_value : nil }.compact
          end

          def root_variables_inheritance
            inherit_entry&.variables_entry&.value
          end

          def manual_action?
            self.when == 'manual'
          end
        end
      end
    end
  end
end

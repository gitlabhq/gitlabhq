# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a CI/CD Bridge job that is responsible for
        # defining a downstream project trigger.
        #
        class Bridge < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Configurable
          include ::Gitlab::Config::Entry::Attributable
          include ::Gitlab::Config::Entry::Inheritable

          ALLOWED_KEYS = %i[trigger stage allow_failure only except
                            when extends variables needs rules].freeze

          validations do
            validates :config, allowed_keys: ALLOWED_KEYS
            validates :config, presence: true
            validates :name, presence: true
            validates :name, type: Symbol
            validates :config, disallowed_keys: {
                in: %i[only except when start_in],
                message: 'key may not be used with `rules`'
              },
              if: :has_rules?

            with_options allow_nil: true do
              validates :when,
                inclusion: { in: %w[on_success on_failure always],
                              message: 'should be on_success, on_failure or always' }
              validates :extends, type: String
              validates :rules, array_of_hashes: true
            end

            validate on: :composed do
              unless trigger.present? || bridge_needs.present?
                errors.add(:config, 'should contain either a trigger or a needs:pipeline')
              end
            end

            validate on: :composed do
              next unless bridge_needs.present?
              next if bridge_needs.one?

              errors.add(:config, 'should contain at most one bridge need')
            end
          end

          entry :trigger, ::Gitlab::Ci::Config::Entry::Trigger,
            description: 'CI/CD Bridge downstream trigger definition.',
            inherit: false

          entry :needs, ::Gitlab::Ci::Config::Entry::Needs,
            description: 'CI/CD Bridge needs dependency definition.',
            inherit: false,
            metadata: { allowed_needs: %i[job bridge] }

          entry :stage, ::Gitlab::Ci::Config::Entry::Stage,
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
              allowed_when: %w[on_success on_failure always never manual delayed].freeze
            }

          entry :variables, ::Gitlab::Ci::Config::Entry::Variables,
            description: 'Environment variables available for this job.',
            inherit: false

          helpers(*ALLOWED_KEYS)
          attributes(*ALLOWED_KEYS)

          def self.matching?(name, config)
            !name.to_s.start_with?('.') &&
              config.is_a?(Hash) &&
              (config.key?(:trigger) || config.key?(:needs))
          end

          def self.visible?
            true
          end

          def compose!(deps = nil)
            super do
              has_workflow_rules = deps&.workflow&.has_rules?

              # If workflow:rules: or rules: are used
              # they are considered not compatible
              # with `only/except` defaults
              #
              # Context: https://gitlab.com/gitlab-org/gitlab/merge_requests/21742
              if has_rules? || has_workflow_rules
                # Remove only/except defaults
                # defaults are not considered as defined
                @entries.delete(:only) unless only_defined?
                @entries.delete(:except) unless except_defined?
              end
            end
          end

          def has_rules?
            @config&.key?(:rules)
          end

          def name
            @metadata[:name]
          end

          def value
            { name: name,
              trigger: (trigger_value if trigger_defined?),
              needs: (needs_value if needs_defined?),
              ignore: !!allow_failure,
              stage: stage_value,
              when: when_value,
              extends: extends_value,
              variables: (variables_value if variables_defined?),
              rules: (rules_value if has_rules?),
              only: only_value,
              except: except_value }.compact
          end

          def bridge_needs
            needs_value[:bridge] if needs_value
          end

          private

          def overwrite_entry(deps, key, current_entry)
            deps.default[key] unless current_entry.specified?
          end
        end
      end
    end
  end
end

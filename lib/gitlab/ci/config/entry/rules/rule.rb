# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        # A rule is a condition that is evaluated before a job is executed.
        # Until we find a better solution in https://gitlab.com/gitlab-org/gitlab/-/issues/436473,
        # these two metadata parameters need to be passed to `Entry::Rules`:
        # - `allowed_when`: a list of allowed values for the `when` keyword.
        # - `allowed_keys`: a list of allowed keys for each rule.
        class Rules::Rule < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Validatable
          include ::Gitlab::Config::Entry::Configurable
          include ::Gitlab::Config::Entry::Attributable

          attributes :if, :when, :start_in, :allow_failure, :interruptible

          entry :changes, Entry::Rules::Rule::Changes,
            description: 'File change condition rule.'

          entry :exists, Entry::Rules::Rule::Exists,
            description: 'File exists condition rule.'

          entry :variables, Entry::Variables,
            description: 'Environment variables to define for rule conditions.'

          entry :needs, Entry::Needs,
            description: 'Needs configuration to define for rule conditions.',
            metadata: { allowed_needs: %i[job] },
            inherit: false

          entry :auto_cancel, Entry::AutoCancel,
            description: 'Auto-cancel configuration for the pipeline.'

          validations do
            validates :config, presence: true
            validates :config, type: { with: Hash }
            validates :config, disallowed_keys: %i[start_in], unless: :specifies_delay?
            validates :start_in, presence: true, if: :specifies_delay?
            validates :start_in, duration: { limit: '1 week' }, if: :specifies_delay?

            with_options allow_nil: true do
              validates :if, expression: true
              validates :allow_failure, boolean: true
              validates :interruptible, boolean: true
            end

            validate do
              # This validation replaces the old `validates :when, allowed_values: { in: ALLOWED_WHEN }` validation.
              # In https://gitlab.com/gitlab-org/gitlab/-/issues/436473, we'll remove this custom validation.
              validates_with Gitlab::Config::Entry::Validators::AllowedValuesValidator,
                attributes: %i[when],
                allow_nil: true,
                in: opt(:allowed_when)

              # This validation replaces the old `validates :config, allowed_keys: ALLOWED_KEYS` validation.
              # In https://gitlab.com/gitlab-org/gitlab/-/issues/436473, we'll remove this custom validation.
              validates_with Gitlab::Config::Entry::Validators::AllowedKeysValidator,
                attributes: %i[config],
                in: opt(:allowed_keys)
            end
          end

          def value
            config.merge(
              changes: (changes_value if changes_defined?),
              exists: (exists_value if exists_defined?),
              variables: (variables_value if variables_defined?),
              needs: (needs_value if needs_defined?),
              auto_cancel: (auto_cancel_value if auto_cancel_defined?)
            ).compact
          end

          def specifies_delay?
            self.when == 'delayed'
          end

          def default; end
        end
      end
    end
  end
end

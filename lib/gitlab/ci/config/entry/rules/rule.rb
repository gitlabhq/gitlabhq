# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        class Rules::Rule < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Validatable
          include ::Gitlab::Config::Entry::Configurable
          include ::Gitlab::Config::Entry::Attributable

          ALLOWED_KEYS = %i[if changes exists when start_in allow_failure variables needs].freeze
          ALLOWED_WHEN = %w[on_success on_failure always never manual delayed].freeze

          attributes :if, :exists, :when, :start_in, :allow_failure

          entry :changes, Entry::Rules::Rule::Changes,
            description: 'File change condition rule.'

          entry :variables, Entry::Variables,
            description: 'Environment variables to define for rule conditions.'

          entry :needs, Entry::Needs,
            description: 'Needs configuration to define for rule conditions.',
            metadata: { allowed_needs: %i[job] },
            inherit: false

          validations do
            validates :config, presence: true
            validates :config, type: { with: Hash }
            validates :config, allowed_keys: ALLOWED_KEYS
            validates :config, disallowed_keys: %i[start_in], unless: :specifies_delay?
            validates :start_in, presence: true, if: :specifies_delay?
            validates :start_in, duration: { limit: '1 week' }, if: :specifies_delay?

            with_options allow_nil: true do
              validates :if, expression: true
              validates :exists, array_of_strings: true, length: { maximum: 50 }
              validates :when, allowed_values: { in: ALLOWED_WHEN }
              validates :allow_failure, boolean: true
            end

            validate do
              validates_with Gitlab::Config::Entry::Validators::AllowedValuesValidator,
                attributes: %i[when],
                allow_nil: true,
                in: opt(:allowed_when)
            end
          end

          def value
            config.merge(
              changes: (changes_value if changes_defined?),
              variables: (variables_value if variables_defined?),
              needs: (needs_value if needs_defined?)
            ).compact
          end

          def specifies_delay?
            self.when == 'delayed'
          end

          def default
          end
        end
      end
    end
  end
end

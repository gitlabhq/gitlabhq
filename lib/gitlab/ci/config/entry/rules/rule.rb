# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        class Rules::Rule < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Validatable
          include ::Gitlab::Config::Entry::Attributable

          CLAUSES        = %i[if changes exists].freeze
          ALLOWED_KEYS   = %i[if changes exists when start_in].freeze
          ALLOWABLE_WHEN = %w[on_success on_failure always never manual delayed].freeze

          attributes :if, :changes, :exists, :when, :start_in

          validations do
            validates :config, presence: true
            validates :config, type: { with: Hash }
            validates :config, allowed_keys: ALLOWED_KEYS
            validates :config, disallowed_keys: %i[start_in], unless: :specifies_delay?
            validates :start_in, presence: true, if: :specifies_delay?
            validates :start_in, duration: { limit: '1 day' }, if: :specifies_delay?

            with_options allow_nil: true do
              validates :if, expression: true
              validates :changes, :exists, array_of_strings: true, length: { maximum: 50 }
              validates :when, allowed_values: { in: ALLOWABLE_WHEN }
            end

            validate do
              validates_with Gitlab::Config::Entry::Validators::AllowedValuesValidator,
                attributes: %i[when],
                allow_nil: true,
                in: opt(:allowed_when)
            end
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

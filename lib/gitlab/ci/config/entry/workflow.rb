# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        class Workflow < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Configurable
          include ::Gitlab::Config::Entry::Validatable
          include ::Gitlab::Config::Entry::Attributable

          ALLOWED_KEYS = %i[rules name auto_cancel].freeze

          attributes :name

          validations do
            validates :config, type: Hash
            validates :config, allowed_keys: ALLOWED_KEYS
            validates :name, allow_nil: true, length: { minimum: 1, maximum: 255 }
          end

          # `start_in`, `allow_failure`, and `needs` should not be allowed but we can't break this behavior now.
          # More information: https://gitlab.com/gitlab-org/gitlab/-/issues/436473
          entry :rules, Entry::Rules,
            description: 'List of evaluable Rules to determine Pipeline status.',
            metadata: {
              allowed_when: %w[always never].freeze,
              allowed_keys: %i[if changes exists when start_in allow_failure variables needs auto_cancel].freeze
            }

          entry :auto_cancel, Entry::AutoCancel,
            description: 'Auto-cancel configuration for this pipeline.'

          def has_rules?
            @config.try(:key?, :rules)
          end
        end
      end
    end
  end
end

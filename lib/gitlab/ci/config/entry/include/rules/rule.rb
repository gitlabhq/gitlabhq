# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        class Include
          class Rules::Rule < ::Gitlab::Config::Entry::Node
            include ::Gitlab::Config::Entry::Validatable
            include ::Gitlab::Config::Entry::Attributable

            ALLOWED_KEYS = %i[if exists when].freeze
            ALLOWED_WHEN = %w[never].freeze

            attributes :if, :exists, :when

            # Include rules are validated before Entry validations. This is because
            # the include files are expanded before `compose!` runs in Ci::Config.
            # The actual validation logic is in lib/gitlab/ci/config/external/rules.rb.
            validations do
              validates :config, presence: true
              validates :config, type: { with: Hash }
              validates :config, allowed_keys: ALLOWED_KEYS

              with_options allow_nil: true do
                validates :if, expression: true
              end
            end
          end
        end
      end
    end
  end
end

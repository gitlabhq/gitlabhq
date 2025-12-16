# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Header
        class Input
          class Rules
            ##
            # A rule defines conditional options and defaults for an input based on expressions.
            #
            class Rule < ::Gitlab::Config::Entry::Node
              include ::Gitlab::Config::Entry::Validatable
              include ::Gitlab::Config::Entry::Attributable

              ALLOWED_KEYS = %i[if options default].freeze

              attributes :if, :options

              validations do
                validates :config, presence: true
                validates :config, type: { with: Hash }
                validates :config, allowed_keys: ALLOWED_KEYS

                with_options allow_nil: true do
                  validates :if, expression: true
                  validates :options, type: Array
                end

                validate do
                  next if errors.any?

                  if options.is_a?(Array) && options.size > Input::ALLOWED_OPTIONS_LIMIT
                    errors.add(:config, "cannot define more than #{Input::ALLOWED_OPTIONS_LIMIT} options")
                  end

                  has_default = config.key?(:default)
                  has_options = options.is_a?(Array) && options.any?

                  if !has_options && !has_default
                    errors.add(:base, "rule must define 'options' with at least one value and a 'default'")
                  end

                  if has_options && !has_default
                    errors.add(:base, "rule must define 'options' with at least one value and a 'default'")
                  end

                  if has_default && has_options && options.exclude?(config[:default])
                    errors.add(:base, "default '#{config[:default]}' must be one of the options")
                  end
                end
              end

              def value
                config
              end

              def default; end
            end
          end
        end
      end
    end
  end
end

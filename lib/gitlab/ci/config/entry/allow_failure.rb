# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents allow_failure settings.
        #
        class AllowFailure < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Attributable
          include ::Gitlab::Config::Entry::Validatable

          ALLOWED_KEYS = %i[exit_codes].freeze
          attributes ALLOWED_KEYS

          validations do
            validates :config, hash_or_boolean: true
            validates :config, allowed_keys: ALLOWED_KEYS
            validates :exit_codes, array_of_integers_or_integer: true, allow_nil: true
          end

          def value
            @config[:exit_codes] = Array.wrap(exit_codes) if exit_codes.present?
            @config
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Header
        class Spec < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Configurable
          include ::Gitlab::Config::Entry::Attributable

          ALLOWED_ENTRIES = %i[inputs include component].freeze
          ALLOWED_ATTRIBUTES = %i[description].freeze
          ALLOWED_KEYS = (ALLOWED_ENTRIES + ALLOWED_ATTRIBUTES).freeze

          attributes ALLOWED_ATTRIBUTES, prefix: :config

          validations do
            validates :config, allowed_keys: ALLOWED_KEYS
            validates :config_description, type: String, length: { maximum: 256 }, allow_nil: true
          end

          entry :inputs, ::Gitlab::Config::Entry::ComposableHash,
            description: 'Allowed input parameters used for interpolation.',
            inherit: false,
            metadata: { composable_class: ::Gitlab::Ci::Config::Header::Input }

          entry :include, ::Gitlab::Ci::Config::Header::Includes,
            description: 'List of input files to include.',
            inherit: false

          entry :component, Header::Component,
            description: 'The available component context used for interpolation.',
            inherit: false,
            default: []
        end
      end
    end
  end
end

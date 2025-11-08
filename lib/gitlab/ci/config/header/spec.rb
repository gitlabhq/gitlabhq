# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Header
        class Spec < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Configurable

          ALLOWED_KEYS = %i[inputs include component].freeze

          validations do
            validates :config, allowed_keys: ALLOWED_KEYS

            validate on: :composed do
              if config.is_a?(Hash) && config.key?(:include) &&
                  !Gitlab::Ci::Config::FeatureFlags.enabled?(:ci_file_inputs)
                errors.add(:config, "contains unknown keys: include")
              end
            end
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

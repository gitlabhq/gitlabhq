# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Header
        class Spec < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Configurable

          ALLOWED_KEYS = %i[inputs].freeze

          validations do
            validates :config, allowed_keys: ALLOWED_KEYS
          end

          entry :inputs, ::Gitlab::Config::Entry::ComposableHash,
            description: 'Allowed input parameters used for interpolation.',
            inherit: false,
            metadata: { composable_class: ::Gitlab::Ci::Config::Header::Input }
        end
      end
    end
  end
end

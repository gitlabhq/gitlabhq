# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        class Kubernetes < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Validatable
          include ::Gitlab::Config::Entry::Attributable

          ALLOWED_KEYS = %i[namespace].freeze

          attributes ALLOWED_KEYS

          validations do
            validates :config, type: Hash
            validates :config, allowed_keys: ALLOWED_KEYS

            validates :namespace, type: String, presence: true
          end
        end
      end
    end
  end
end

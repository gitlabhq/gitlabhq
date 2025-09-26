# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Header
        class Include < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Ci::Config::Entry::Concerns::BaseInclude

          # Header includes only use the common allowed keys (no additional keys)
          ALLOWED_KEYS = [] + COMMON_ALLOWED_KEYS

          validations do
            validates :config, allowed_keys: ALLOWED_KEYS
          end
        end
      end
    end
  end
end

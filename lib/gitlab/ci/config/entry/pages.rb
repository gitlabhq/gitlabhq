# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents the pages path prefix
        # Entry that represents the pages attributes
        #
        class Pages < ::Gitlab::Config::Entry::Node
          ALLOWED_KEYS = %i[path_prefix].freeze

          include ::Gitlab::Config::Entry::Attributable
          include ::Gitlab::Config::Entry::Validatable

          attributes ALLOWED_KEYS

          validations do
            validates :config, type: Hash
            validates :config, allowed_keys: ALLOWED_KEYS

            with_options allow_nil: true do
              validates :path_prefix, type: String
            end
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module Gitlab
  module StaticSiteEditor
    module Config
      class FileConfig
        module Entry
          ##
          # Entry that represents the mappings of mounted source directories to target paths
          #
          class Mount < ::Gitlab::Config::Entry::Node
            include ::Gitlab::Config::Entry::Validatable
            include ::Gitlab::Config::Entry::Attributable

            ALLOWED_KEYS = %i[source target].freeze

            attributes ALLOWED_KEYS

            validations do
              validates :config, allowed_keys: ALLOWED_KEYS

              validates :source, type: String, presence: true
              validates :target, type: String, presence: true, allow_blank: true
            end

            def self.default
              # NOTE: This is the default for middleman projects.  Ideally, this would be determined
              #       based on the defaults for whatever `static_site_generator` is configured.
              {
                source: 'source',
                target: ''
              }
            end
          end
        end
      end
    end
  end
end

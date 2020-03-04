# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a configuration of release assets.
        #
        class Release
          class Assets < ::Gitlab::Config::Entry::Node
            include ::Gitlab::Config::Entry::Configurable
            include ::Gitlab::Config::Entry::Validatable
            include ::Gitlab::Config::Entry::Attributable

            ALLOWED_KEYS = %i[links].freeze
            attributes ALLOWED_KEYS

            entry :links, Entry::Release::Assets::Links, description: 'Release assets:links.'

            validations do
              validates :config, allowed_keys: ALLOWED_KEYS
              validates :links, array_of_hashes: true, presence: true
            end

            def value
              @config[:links] = links_value if @config.key?(:links)
              @config
            end
          end
        end
      end
    end
  end
end

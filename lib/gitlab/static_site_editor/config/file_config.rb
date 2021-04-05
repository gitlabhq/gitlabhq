# frozen_string_literal: true

module Gitlab
  module StaticSiteEditor
    module Config
      #
      # Base GitLab Static Site Editor Configuration facade
      #
      class FileConfig
        ConfigError = Class.new(StandardError)

        def initialize(yaml)
          content_hash = content_hash(yaml)
          @global = Entry::Global.new(content_hash)
          @global.compose!
        rescue Gitlab::Config::Loader::FormatError => e
          raise FileConfig::ConfigError, e.message
        end

        def valid?
          @global.valid?
        end

        def errors
          @global.errors
        end

        def to_hash_with_defaults
          # NOTE: The current approach of simply mapping all the descendents' keys and values ('config')
          #       into a flat hash may need to be enhanced as we add more complex, non-scalar entries.
          @global.descendants.to_h { |descendant| [descendant.key, descendant.config] }
        end

        private

        def content_hash(yaml)
          Gitlab::Config::Loader::Yaml.new(yaml).load!
        end
      end
    end
  end
end

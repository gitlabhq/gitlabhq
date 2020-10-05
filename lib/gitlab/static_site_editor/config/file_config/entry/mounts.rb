# frozen_string_literal: true

module Gitlab
  module StaticSiteEditor
    module Config
      class FileConfig
        module Entry
          ##
          # Entry that represents the mappings of mounted source directories to target paths
          #
          class Mounts < ::Gitlab::Config::Entry::Node
            include ::Gitlab::Config::Entry::Configurable
            include ::Gitlab::Config::Entry::Validatable

            entry :mount, Entry::Mount, description: 'Configuration of a Static Site Editor mount.'

            validations do
              validates :config, type: Array, presence: true
            end

            def skip_config_hash_validation?
              true
            end

            def self.default
              [Entry::Mount.default]
            end
          end
        end
      end
    end
  end
end

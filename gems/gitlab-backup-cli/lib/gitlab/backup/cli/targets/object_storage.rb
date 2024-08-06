# frozen_string_literal: true

require "google/cloud/storage_transfer"

require_relative "object_storage/google"

module Gitlab
  module Backup
    module Cli
      module Targets
        class ObjectStorage
          SUPPORTED_PROVIDERS = [
            "Google"
          ].freeze

          def self.find_task(object_type, options, config)
            # For objects that don't use the consolidated config (like the registry), try the global
            # object_store for connection information. This will go away with a config file
            # https://gitlab.com/gitlab-org/gitlab/-/issues/475114
            const_get(config.object_store.connection.provider, false).new(object_type, options, config)
          end
        end
      end
    end
  end
end

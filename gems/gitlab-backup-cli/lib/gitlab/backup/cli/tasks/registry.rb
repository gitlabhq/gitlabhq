# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Tasks
        class Registry < Task
          def self.id = 'registry'

          def enabled = Gitlab.config.registry.enabled

          def human_name = _('container registry images')

          def destination_path = 'registry.tar.gz'

          private

          def target
            ::Backup::Targets::Files.new(nil, storage_path, options: options)
          end

          def storage_path = context.registry_path
        end
      end
    end
  end
end

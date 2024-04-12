# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Tasks
        class Lfs < Task
          def self.id = 'lfs'

          def human_name = _('lfs objects')

          def destination_path = 'lfs.tar.gz'

          private

          def target
            ::Backup::Targets::Files.new(nil, storage_path, options: options)
          end

          def storage_path = context.ci_lfs_path
        end
      end
    end
  end
end

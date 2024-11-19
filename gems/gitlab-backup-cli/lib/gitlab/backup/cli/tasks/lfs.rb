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

          def local
            Gitlab::Backup::Cli::Targets::Files.new(context, storage_path)
          end

          def storage_path = context.ci_lfs_path
        end
      end
    end
  end
end

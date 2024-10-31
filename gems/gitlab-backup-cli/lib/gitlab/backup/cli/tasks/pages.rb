# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Tasks
        class Pages < Task
          # pages used to deploy tmp files to this path
          # if some of these files are still there, we don't need them in the backup
          LEGACY_PAGES_TMP_PATH = '@pages.tmp'

          def self.id = 'pages'

          def human_name = _('pages')

          def destination_path = 'pages.tar.gz'

          private

          def local
            Gitlab::Backup::Cli::Targets::Files.new(context, storage_path, excludes: [LEGACY_PAGES_TMP_PATH])
          end

          def storage_path = context.pages_path
        end
      end
    end
  end
end

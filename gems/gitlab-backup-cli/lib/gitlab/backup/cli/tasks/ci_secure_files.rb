# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Tasks
        class CiSecureFiles < Task
          def self.id = 'ci_secure_files'

          def human_name = _('ci secure files')

          def destination_path = 'ci_secure_files.tar.gz'

          private

          def target
            ::Backup::Targets::Files.new(nil, storage_path, options: options, excludes: ['tmp'])
          end

          def storage_path = context.ci_secure_files_path
        end
      end
    end
  end
end

# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Errors
        class FileBackupError < StandardError
          attr_reader :storage_path, :backup_tarball

          def initialize(app_files_dir, backup_tarball)
            @storage_path = app_files_dir
            @backup_tarball = backup_tarball
          end

          def message
            "Failed to create compressed file '#{backup_tarball}' " \
              "when trying to backup the following paths: '#{storage_path}' "
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Errors
        autoload :DatabaseBackupError, 'gitlab/backup/cli/errors/database_backup_error'
        autoload :FileBackupError, 'gitlab/backup/cli/errors/file_backup_error'
      end
    end
  end
end

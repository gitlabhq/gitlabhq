# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Commands
        autoload :BackupSubcommand, 'gitlab/backup/cli/commands/backup_subcommand'
        autoload :Command, 'gitlab/backup/cli/commands/command'
        autoload :ObjectStorageCommand, 'gitlab/backup/cli/commands/object_storage_command'
        autoload :RestoreSubcommand, 'gitlab/backup/cli/commands/restore_subcommand'
      end
    end
  end
end

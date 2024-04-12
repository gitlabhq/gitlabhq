# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Commands
        autoload :BackupSubcommand, 'gitlab/backup/cli/commands/backup_subcommand'
        autoload :Command, 'gitlab/backup/cli/commands/command'
      end
    end
  end
end

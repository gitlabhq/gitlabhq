# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Services
        autoload :Database, 'gitlab/backup/cli/services/database'
        autoload :Postgres, 'gitlab/backup/cli/services/postgres'
        autoload :GitalyBackup, 'gitlab/backup/cli/services/gitaly_backup'
        autoload :GitalyClient, 'gitlab/backup/cli/services/gitaly_client'
      end
    end
  end
end

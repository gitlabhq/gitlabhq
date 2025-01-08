# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Services
        autoload :Database, 'gitlab/backup/cli/services/database'
        autoload :Postgres, 'gitlab/backup/cli/services/postgres'
      end
    end
  end
end

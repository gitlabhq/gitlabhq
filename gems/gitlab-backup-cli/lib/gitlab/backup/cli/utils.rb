# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Utils
        autoload :PgDump, 'gitlab/backup/cli/utils/pg_dump'
      end
    end
  end
end

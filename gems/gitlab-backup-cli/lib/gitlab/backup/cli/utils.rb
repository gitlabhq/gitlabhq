# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Utils
        autoload :Compression, 'gitlab/backup/cli/utils/compression'
        autoload :PgDump, 'gitlab/backup/cli/utils/pg_dump'
        autoload :PoolRepositories, 'gitlab/backup/cli/utils/pool_repositories'
        autoload :Rake, 'gitlab/backup/cli/utils/rake'
        autoload :Tar, 'gitlab/backup/cli/utils/tar'
      end
    end
  end
end

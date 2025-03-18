# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Targets
        autoload :Target, 'gitlab/backup/cli/targets/target'
        autoload :Database, 'gitlab/backup/cli/targets/database'
        autoload :Files, 'gitlab/backup/cli/targets/files'
        autoload :ObjectStorage, 'gitlab/backup/cli/targets/object_storage'
        autoload :Repositories, 'gitlab/backup/cli/targets/repositories'
      end
    end
  end
end

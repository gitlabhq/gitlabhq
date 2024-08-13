# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Targets
        autoload :Target, 'gitlab/backup/cli/targets/target'
        autoload :Database, 'gitlab/backup/cli/targets/database'
        autoload :ObjectStorage, 'gitlab/backup/cli/targets/object_storage'
      end
    end
  end
end

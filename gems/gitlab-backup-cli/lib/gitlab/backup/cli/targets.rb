# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Targets
        autoload :Target, 'gitlab/backup/cli/targets/target'
        autoload :Database, 'gitlab/backup/cli/targets/database'
      end
    end
  end
end

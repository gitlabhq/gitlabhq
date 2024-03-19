# frozen_string_literal: true

autoload :Open3, 'open3'

module Gitlab
  module Backup
    module Cli
      module Shell
        autoload :Command, 'gitlab/backup/cli/shell/command'
        autoload :Pipeline, 'gitlab/backup/cli/shell/pipeline'
      end
    end
  end
end

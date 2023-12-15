# frozen_string_literal: true

module Gitlab
  module Backup
    # GitLab Backup CLI
    module Cli
      autoload :VERSION, 'gitlab/backup/cli/version'
      autoload :Runner, 'gitlab/backup/cli/runner'
      autoload :Utils, 'gitlab/backup/cli/utils'

      Error = Class.new(StandardError)
      # Your code goes here...
    end
  end
end

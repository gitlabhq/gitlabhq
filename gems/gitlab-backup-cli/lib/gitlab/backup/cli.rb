# frozen_string_literal: true

module Gitlab
  module Backup
    # GitLab Backup CLI
    module Cli
      autoload :VERSION, 'gitlab/backup/cli/version'
      autoload :Runner, 'gitlab/backup/cli/runner'

      class Error < StandardError; end
      # Your code goes here...
    end
  end
end

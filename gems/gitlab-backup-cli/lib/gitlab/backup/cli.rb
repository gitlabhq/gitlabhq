# frozen_string_literal: true

# TODO: currently we're using a lot of legacy code from lib/backup here which
# requires "rainbow/ext/string" to define the String#color method. We
# want to use the Rainbow refinement in the gem code going forward, but
# while we have this dependency, we need this external require
require "rainbow/ext/string"
require 'active_support/all'

module Gitlab
  module Backup
    # GitLab Backup CLI
    module Cli
      autoload :BackupExecutor, 'gitlab/backup/cli/backup_executor'
      autoload :Commands, 'gitlab/backup/cli/commands'
      autoload :Context, 'gitlab/backup/cli/context'
      autoload :Dependencies, 'gitlab/backup/cli/dependencies'
      autoload :Errors, 'gitlab/backup/cli/errors'
      autoload :GitlabConfig, 'gitlab/backup/cli/gitlab_config'
      autoload :Metadata, 'gitlab/backup/cli/metadata'
      autoload :Output, 'gitlab/backup/cli/output'
      autoload :RestoreExecutor, 'gitlab/backup/cli/restore_executor'
      autoload :Runner, 'gitlab/backup/cli/runner'
      autoload :Shell, 'gitlab/backup/cli/shell'
      autoload :Targets, 'gitlab/backup/cli/targets'
      autoload :Tasks, 'gitlab/backup/cli/tasks'
      autoload :Utils, 'gitlab/backup/cli/utils'
      autoload :VERSION, 'gitlab/backup/cli/version'

      Error = Class.new(StandardError)

      def self.rails_environment!
        require File.join(GITLAB_PATH, 'config/application')

        Rails.application.require_environment!
        Rails.application.autoloaders
        Rails.application.load_tasks
      end
    end
  end
end

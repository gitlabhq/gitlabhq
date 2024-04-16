# frozen_string_literal: true

module Gitlab
  module Backup
    # GitLab Backup CLI
    module Cli
      autoload :BackupExecutor, 'gitlab/backup/cli/backup_executor'
      autoload :Commands, 'gitlab/backup/cli/commands'
      autoload :Dependencies, 'gitlab/backup/cli/dependencies'
      autoload :BackupMetadata, 'gitlab/backup/cli/backup_metadata'
      autoload :Output, 'gitlab/backup/cli/output'
      autoload :Runner, 'gitlab/backup/cli/runner'
      autoload :SourceContext, 'gitlab/backup/cli/source_context'
      autoload :Shell, 'gitlab/backup/cli/shell'
      autoload :Targets, 'gitlab/backup/cli/targets'
      autoload :Tasks, 'gitlab/backup/cli/tasks'
      autoload :Utils, 'gitlab/backup/cli/utils'
      autoload :VERSION, 'gitlab/backup/cli/version'

      Error = Class.new(StandardError)

      def self.rails_environment!
        require APP_PATH

        Rails.application.require_environment!
        Rails.application.autoloaders
      end
    end
  end
end

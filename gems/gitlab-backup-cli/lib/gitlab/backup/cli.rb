# frozen_string_literal: true

require 'active_support/all' # Used to provide timezone support on timestamp among other things
require 'active_record' # Used to connect to database views to help run gitaly backups
require 'tmpdir' # Used to create temporary folders during backup
require 'base64' # Used by gitaly backup client

module Gitlab
  module Backup
    # GitLab Backup CLI
    module Cli
      autoload :BackupExecutor, 'gitlab/backup/cli/backup_executor'
      autoload :BaseExecutor, 'gitlab/backup/cli/base_executor'
      autoload :Commands, 'gitlab/backup/cli/commands'
      autoload :Context, 'gitlab/backup/cli/context'
      autoload :Services, 'gitlab/backup/cli/services'
      autoload :Dependencies, 'gitlab/backup/cli/dependencies'
      autoload :Errors, 'gitlab/backup/cli/errors'
      autoload :GitlabConfig, 'gitlab/backup/cli/gitlab_config'
      autoload :Metadata, 'gitlab/backup/cli/metadata'
      autoload :Models, 'gitlab/backup/cli/models'
      autoload :Output, 'gitlab/backup/cli/output'
      autoload :RestoreExecutor, 'gitlab/backup/cli/restore_executor'
      autoload :Runner, 'gitlab/backup/cli/runner'
      autoload :Shell, 'gitlab/backup/cli/shell'
      autoload :Targets, 'gitlab/backup/cli/targets'
      autoload :Tasks, 'gitlab/backup/cli/tasks'
      autoload :Utils, 'gitlab/backup/cli/utils'
      autoload :VERSION, 'gitlab/backup/cli/version'

      Error = Class.new(StandardError)

      # Entrypoint for the application
      # Run any initialization logic from here
      def self.start(argv)
        # Set a custom process name
        update_process_title!

        Gitlab::Backup::Cli::Runner.start(argv)
      end

      def self.update_process_title!(status_message = nil)
        process_title = status_message ? "gitlab-backup-cli: #{status_message}" : "gitlab-backup-cli"

        Process.setproctitle(process_title)
      end

      def self.root
        Pathname.new(File.expand_path(File.join(__dir__, '../../../')))
      end
    end
  end
end

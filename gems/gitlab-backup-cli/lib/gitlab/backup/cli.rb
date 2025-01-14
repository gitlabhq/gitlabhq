# frozen_string_literal: true

# TODO: currently we're using a lot of legacy code from lib/backup here which
# requires "rainbow/ext/string" to define the String#color method. We
# want to use the Rainbow refinement in the gem code going forward, but
# while we have this dependency, we need this external require
require "rainbow/ext/string"
require 'active_support/all'
require 'active_record'

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
      autoload :Output, 'gitlab/backup/cli/output'
      autoload :RepoType, 'gitlab/backup/cli/repo_type'
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

      def self.rails_environment!
        require File.join(GITLAB_PATH, 'config/application')

        Rails.application.require_environment!
        Rails.application.autoloaders
        Rails.application.load_tasks
      end
    end
  end
end

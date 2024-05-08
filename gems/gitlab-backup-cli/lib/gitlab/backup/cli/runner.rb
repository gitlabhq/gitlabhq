# frozen_string_literal: true

require 'thor'

module Gitlab
  module Backup
    module Cli
      # GitLab Backup CLI
      #
      # This supersedes the previous backup rake files and will be
      # the default interface to handle backups
      class Runner < Commands::Command
        package_name 'GitLab Backup CLI'

        map %w[--version -v] => :version
        desc 'version', 'Display the version information'
        def version
          puts "GitLab Backup CLI (#{VERSION})" # rubocop:disable Rails/Output -- CLI output
        end

        desc 'backup', 'Manage repositories, database and files backup creation'
        subcommand 'backup', Commands::BackupSubcommand

        desc 'restore', 'Restore previously captured backup data'
        subcommand 'restore', Commands::RestoreSubcommand
      end
    end
  end
end

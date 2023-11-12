# frozen_string_literal: true

require 'thor'

module Gitlab
  module Backup
    module Cli
      # GitLab Backup CLI
      #
      # This supersedes the previous backup rake files and will be
      # the default interface to handle backups
      class Runner < Thor
        def self.exit_on_failure?
          true
        end

        map %w[--version -v] => :version
        desc 'version', 'Display the version information'

        def version
          puts "GitLab Backup CLI (#{VERSION})" # rubocop:disable Rails/Output -- CLI output
        end

        private

        def rails_environment!
          require APP_PATH

          Rails.application.load_tasks
        end
      end
    end
  end
end

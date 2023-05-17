# frozen_string_literal: true

# Import large project archives
#
# This task:
#   1. Disables ObjectStorage for archive upload
#   2. Performs Sidekiq job synchronously
#
# @example
#   bundle exec rake "gitlab:import_export:import[root, root, imported_project, /path/to/file.tar.gz]"
#
namespace :gitlab do
  namespace :import_export do
    desc 'GitLab | Import/Export | EXPERIMENTAL | Import large project archives'
    task :import, [:username, :namespace_path, :project_path, :archive_path] => :gitlab_environment do |_t, args|
      # Load it here to avoid polluting Rake tasks with Sidekiq test warnings
      require 'sidekiq/testing'

      logger = Logger.new($stdout)

      begin
        warn_user_is_not_gitlab

        if ENV['IMPORT_DEBUG'].present?
          Gitlab::Utils::Measuring.logger = logger
          ActiveRecord::Base.logger = logger
          logger.level = Logger::DEBUG
        else
          logger.level = Logger::INFO
        end

        task = Gitlab::ImportExport::Project::ImportTask.new(
          {
            namespace_path: args.namespace_path,
            project_path: args.project_path,
            username: args.username,
            file_path: args.archive_path
          },
          logger: logger
        )

        success = task.import

        exit(success)
      rescue StandardError => e
        logger.error "Exception: #{e.message}"
        logger.debug e.backtrace
        exit 1
      end
    end
  end
end

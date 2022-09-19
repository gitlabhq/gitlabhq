# frozen_string_literal: true

# Export project to archive
#
# @example
#   bundle exec rake "gitlab:import_export:export[root, root, project_to_export, /path/to/file.tar.gz]"
#
namespace :gitlab do
  namespace :import_export do
    desc 'GitLab | Import/Export | EXPERIMENTAL | Export large project archives'
    task :export, [:username, :namespace_path, :project_path, :archive_path] => :gitlab_environment do |_t, args|
      # Load it here to avoid polluting Rake tasks with Sidekiq test warnings
      require 'sidekiq/testing'

      logger = Logger.new($stdout)

      begin
        warn_user_is_not_gitlab

        if ENV['EXPORT_DEBUG'].present?
          Gitlab::Utils::Measuring.logger = logger
          ActiveRecord::Base.logger = logger
          logger.level = Logger::DEBUG
        else
          logger.level = Logger::INFO
        end

        task = Gitlab::ImportExport::Project::ExportTask.new(
          namespace_path: args.namespace_path,
          project_path: args.project_path,
          username: args.username,
          file_path: args.archive_path,
          logger: logger
        )

        success = task.export

        exit(success)
      rescue StandardError => e
        logger.error "Exception: #{e.message}"
        logger.debug e.backtrace
        exit 1
      end
    end
  end
end

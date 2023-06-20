# frozen_string_literal: true

desc "GitLab | CI Secure Files | Migrate Secure Files to remote storage"
namespace :gitlab do
  namespace :ci_secure_files do
    task migrate: :environment do
      require 'logger'

      logger = Logger.new($stdout)
      logger.info('Starting transfer of Secure Files to object storage')

      begin
        Gitlab::Ci::SecureFiles::MigrationHelper.migrate_to_remote_storage do |file|
          message = "Transferred Secure File ID #{file.id} (#{file.name}) to object storage"

          logger.info(message)
        end
      rescue StandardError => e
        logger.error("Failed to migrate: #{e.message}")
      end
    end
  end
end

require 'logger'
require 'resolv-replace'

desc 'GitLab | Artifacts | Migrate files for artifacts to comply with new storage format'
namespace :gitlab do
  namespace :artifacts do
    task migrate: :environment do
      logger = Logger.new(STDOUT)
      logger.info('Starting transfer of artifacts to remote storage')

      helper = Gitlab::Artifacts::MigrationHelper.new

      begin
        helper.migrate_to_remote_storage do |artifact|
          logger.info("Transferred artifact ID #{artifact.id} of type #{artifact.file_type} with size #{artifact.size} to object storage")
        end
      rescue => e
        logger.error(e.message)
      end
    end

    task migrate_to_local: :environment do
      logger = Logger.new(STDOUT)
      logger.info('Starting transfer of artifacts to local storage')

      helper = Gitlab::Artifacts::MigrationHelper.new

      begin
        helper.migrate_to_local_storage do |artifact|
          logger.info("Transferred artifact ID #{artifact.id} of type #{artifact.file_type} with size #{artifact.size} to local storage")
        end
      rescue => e
        logger.error(e.message)
      end
    end
  end
end

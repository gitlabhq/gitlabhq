require 'logger'
require 'resolv-replace'

desc "GitLab | Migrate files for artifacts to comply with new storage format"
namespace :gitlab do
  namespace :artifacts do
    task migrate: :environment do
      logger = Logger.new(STDOUT)
      logger.info('Starting transfer of artifacts')

      Ci::Build.joins(:project)
        .with_artifacts_stored_locally
        .find_each(batch_size: 10) do |build|
        begin
          build.artifacts_file.migrate!(ObjectStorage::Store::REMOTE)
          build.artifacts_metadata.migrate!(ObjectStorage::Store::REMOTE)

          logger.info("Transferred artifacts of #{build.id} of #{build.artifacts_size} to object storage")
        rescue => e
          logger.error("Failed to transfer artifacts of #{build.id} with error: #{e.message}")
        end
      end
    end
  end
end

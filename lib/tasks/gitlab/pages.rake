# frozen_string_literal: true

require 'logger'

namespace :gitlab do
  namespace :pages do
    desc "GitLab | Pages | Migrate legacy storage to zip format"
    task migrate_legacy_storage: :gitlab_environment do
      logger.info('Starting to migrate legacy pages storage to zip deployments')

      result = ::Pages::MigrateFromLegacyStorageService.new(logger,
                                                            ignore_invalid_entries: ignore_invalid_entries,
                                                            mark_projects_as_not_deployed: mark_projects_as_not_deployed)
                 .execute_with_threads(threads: migration_threads, batch_size: batch_size)

      logger.info("A total of #{result[:migrated] + result[:errored]} projects were processed.")
      logger.info("- The #{result[:migrated]} projects migrated successfully")
      logger.info("- The #{result[:errored]} projects failed to be migrated")
    end

    desc "GitLab | Pages | DANGER: Removes data which was migrated from legacy storage on zip storage. Can be used if some bugs in migration are discovered and migration needs to be restarted from scratch."
    task clean_migrated_zip_storage: :gitlab_environment do
      destroyed_deployments = 0

      logger.info("Starting to delete migrated pages deployments")

      ::PagesDeployment.migrated_from_legacy_storage.each_batch(of: batch_size) do |batch|
        destroyed_deployments += batch.count

        # we need to destroy associated files, so can't use delete_all
        batch.destroy_all # rubocop: disable Cop/DestroyAll

        logger.info("#{destroyed_deployments} deployments were deleted")
      end
    end

    def logger
      @logger ||= Logger.new($stdout)
    end

    def migration_threads
      ENV.fetch('PAGES_MIGRATION_THREADS', '3').to_i
    end

    def batch_size
      ENV.fetch('PAGES_MIGRATION_BATCH_SIZE', '10').to_i
    end

    def ignore_invalid_entries
      Gitlab::Utils.to_boolean(
        ENV.fetch('PAGES_MIGRATION_IGNORE_INVALID_ENTRIES', 'false')
      )
    end

    def mark_projects_as_not_deployed
      Gitlab::Utils.to_boolean(
        ENV.fetch('PAGES_MIGRATION_MARK_PROJECTS_AS_NOT_DEPLOYED', 'false')
      )
    end

    namespace :deployments do
      task migrate_to_object_storage: :gitlab_environment do
        logger = Logger.new($stdout)

        helper = Gitlab::LocalAndRemoteStorageMigration::PagesDeploymentMigrater.new(logger)

        begin
          helper.migrate_to_remote_storage
        rescue StandardError => e
          logger.error(e.message)
        end
      end

      task migrate_to_local: :gitlab_environment do
        logger = Logger.new($stdout)

        helper = Gitlab::LocalAndRemoteStorageMigration::PagesDeploymentMigrater.new(logger)

        begin
          helper.migrate_to_local_storage
        rescue StandardError => e
          logger.error(e.message)
        end
      end
    end
  end
end

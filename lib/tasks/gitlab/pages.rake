require 'logger'

namespace :gitlab do
  namespace :pages do
    desc "GitLab | Pages | Migrate legacy storage to zip format"
    task migrate_legacy_storage: :gitlab_environment do
      logger = Logger.new(STDOUT)
      logger.info('Starting to migrate legacy pages storage to zip deployments')

      result = ::Pages::MigrateFromLegacyStorageService.new(logger, migration_threads, batch_size).execute

      logger.info("A total of #{result[:migrated] + result[:errored]} projects were processed.")
      logger.info("- The #{result[:migrated]} projects migrated successfully")
      logger.info("- The #{result[:errored]} projects failed to be migrated")
    end

    def migration_threads
      ENV.fetch('PAGES_MIGRATION_THREADS', '3').to_i
    end

    def batch_size
      ENV.fetch('PAGES_MIGRATION_BATCH_SIZE', '10').to_i
    end
  end
end

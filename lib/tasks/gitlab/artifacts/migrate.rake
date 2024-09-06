# frozen_string_literal: true

desc 'GitLab | Artifacts | Migrate files for artifacts to comply with new storage format'
namespace :gitlab do
  require 'logger'

  namespace :artifacts do
    task migrate: :environment do
      require 'resolv-replace'
      logger = Logger.new($stdout)

      helper = Gitlab::LocalAndRemoteStorageMigration::ArtifactMigrater.new(logger)

      begin
        helper.migrate_to_remote_storage
      rescue StandardError => e
        logger.error(e.message)
      end
    end

    task migrate_to_local: :environment do
      require 'resolv-replace'
      logger = Logger.new($stdout)

      helper = Gitlab::LocalAndRemoteStorageMigration::ArtifactMigrater.new(logger)

      begin
        helper.migrate_to_local_storage
      rescue StandardError => e
        logger.error(e.message)
      end
    end
  end
end

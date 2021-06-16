# frozen_string_literal: true

require 'logger'
require 'resolv-replace'

desc 'GitLab | Artifacts | Migrate files for artifacts to comply with new storage format'
namespace :gitlab do
  namespace :artifacts do
    task migrate: :environment do
      logger = Logger.new($stdout)

      helper = Gitlab::LocalAndRemoteStorageMigration::ArtifactMigrater.new(logger)

      begin
        helper.migrate_to_remote_storage
      rescue StandardError => e
        logger.error(e.message)
      end
    end

    task migrate_to_local: :environment do
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

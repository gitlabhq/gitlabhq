# frozen_string_literal: true

namespace :gitlab do
  namespace :pages do
    namespace :deployments do
      task migrate_to_object_storage: :gitlab_environment do
        require 'logger'

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

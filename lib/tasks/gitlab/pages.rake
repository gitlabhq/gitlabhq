require 'logger'

namespace :gitlab do
  namespace :pages do
    desc "GitLab | Pages | Migrate legacy storage to zip format"
    task migrate_legacy_storage: :gitlab_environment do
      logger = Logger.new(STDOUT)
      logger.info('Starting to migrate legacy pages storage to zip deployments')
      projects_migrated = 0
      projects_errored = 0

      ProjectPagesMetadatum.only_on_legacy_storage.each_batch(of: 10) do |batch|
        batch.preload(project: [:namespace, :route, pages_metadatum: :pages_deployment]).each do |metadatum|
          project = metadatum.project

          result = nil
          time = Benchmark.realtime do
            result = ::Pages::MigrateLegacyStorageToDeploymentService.new(project).execute
          end

          if result[:status] == :success
            logger.info("project_id: #{project.id} #{project.pages_path} has been migrated in #{time} seconds")
            projects_migrated += 1
          else
            logger.error("project_id: #{project.id} #{project.pages_path} failed to be migrated in #{time} seconds: #{result[:message]}")
            projects_errored += 1
          end
        rescue => e
          projects_errored += 1
          logger.error("#{e.message} project_id: #{project&.id}")
          Gitlab::ErrorTracking.track_exception(e, project_id: project&.id)
        end

        logger.info("#{projects_migrated} projects are migrated successfully, #{projects_errored} projects failed to be migrated")
      end

      logger.info("A total of #{projects_migrated + projects_errored} projects were processed.")
      logger.info("- The #{projects_migrated} projects migrated successfully")
      logger.info("- The #{projects_errored} projects failed to be migrated")
    end
  end
end

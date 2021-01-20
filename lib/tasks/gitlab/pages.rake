require 'logger'

namespace :gitlab do
  namespace :pages do
    desc "GitLab | Pages | Migrate legacy storage to zip format"
    task migrate_legacy_storage: :gitlab_environment do
      logger = Logger.new(STDOUT)
      logger.info('Starting to migrate legacy pages storage to zip deployments')
      processed_projects = 0

      ProjectPagesMetadatum.only_on_legacy_storage.each_batch(of: 10) do |batch|
        batch.preload(project: [:namespace, :route, pages_metadatum: :pages_deployment]).each do |metadatum|
          project = metadatum.project

          result = nil
          time = Benchmark.realtime do
            result = ::Pages::MigrateLegacyStorageToDeploymentService.new(project).execute
          end
          processed_projects += 1

          if result[:status] == :success
            logger.info("project_id: #{project.id} #{project.pages_path} has been migrated in #{time} seconds")
          else
            logger.error("project_id: #{project.id} #{project.pages_path} failed to be migrated in #{time} seconds: #{result[:message]}")
          end
        rescue => e
          logger.error("#{e.message} project_id: #{project&.id}")
          Gitlab::ErrorTracking.track_exception(e, project_id: project&.id)
        end

        logger.info("#{processed_projects} pages projects are processed")
      end
    end
  end
end

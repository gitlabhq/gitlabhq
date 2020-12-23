require 'logger'

namespace :gitlab do
  namespace :pages do
    desc "GitLab | Pages | Migrate legacy storage to zip format"
    task migrate_legacy_storage: :gitlab_environment do
      logger = Logger.new(STDOUT)
      logger.info('Starting to migrate legacy pages storage to zip deployments')
      migrated_projects = 0

      ProjectPagesMetadatum.only_on_legacy_storage.each_batch(of: 10) do |batch|
        batch.preload(project: [:namespace, :route, pages_metadatum: :pages_deployment]).each do |metadatum|
          project = metadatum.project
          time = Benchmark.realtime do
            ::Pages::MigrateLegacyStorageToDeploymentService.new(project).execute
          end

          migrated_projects += 1

          logger.info("project_id: #{project.id} #{project.pages_path} has been migrated in #{time} seconds")
        rescue => e
          logger.error("#{e.message} project_id: #{project&.id}")
          Gitlab::ErrorTracking.track_exception(e, project_id: project&.id)
        end

        logger.info("#{migrated_projects} pages projects are migrated")
      end
    end
  end
end

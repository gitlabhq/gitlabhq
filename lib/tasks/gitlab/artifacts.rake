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
          build.artifacts_file.migrate!(ArtifactUploader::REMOTE_STORE)
          build.artifacts_metadata.migrate!(ArtifactUploader::REMOTE_STORE)
          print '.'
        rescue
          print 'F'
        end
      end
    end
  end
end

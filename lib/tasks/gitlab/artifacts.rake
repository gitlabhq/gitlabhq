desc "GitLab | Migrate files for artifacts to comply with new storage format"
namespace :gitlab do
  namespace :artifacts do
    task migrate: :environment do
      puts 'Artifacts'.color(:yellow)
      Ci::Build.joins(:project)
        .with_artifacts
        .order(id: :asc)
        .where(artifacts_file_store: [nil, ArtifactUploader::LOCAL_STORE])
        .find_each(batch_size: 10) do |build|
        begin
          print "Migrating job #{build.id} of size #{build.artifacts_size.to_i.bytes} to remote storage... "
          build.artifacts_file.migrate!(ArtifactUploader::REMOTE_STORE)
          build.artifacts_metadata.migrate!(ArtifactUploader::REMOTE_STORE)
          puts "OK".color(:green)
        rescue => e
          puts "Failed: #{e.message}".color(:red)
        end
      end
    end
  end
end

desc "GitLab | Migrate files for artifacts to comply with new storage format"
task migrate_artifacts: :environment do
  puts 'Artifacts'.color(:yellow)
  Ci::Build.joins(:project)
    .with_artifacts
    .where(artifacts_file_migrated: nil)
    .find_each(batch_size: 100) do |issue|
    begin
      build.artifacts_file.migrate!
      build.artifacts_metadata.migrate!
      build.save! if build.changed?
      print '.'
    rescue
      print 'F'
    end
  end
end

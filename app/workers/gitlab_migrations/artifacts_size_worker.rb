module GitlabMigrations
  class ArtifactsSizeWorker
    include Sidekiq::Worker

    def perform
      cleanup_ci_builds_artifacts_file

      legacy_builds.find_each do |build|
        build.update_artifacts_size
        build.save
      end
    end

    private

    def cleanup_ci_builds_artifacts_file
      Ci::Build.where(artifacts_file: '').update_all(artifacts_file: nil)
    end

    def legacy_builds
      Ci::Build.preload(:project).
        where(artifacts_size: nil).where.not(artifacts_file: '')
    end
  end
end

class ExpireBuildArtifacts
  include Sidekiq::Worker

  def perform
    Rails.logger.info 'Cleaning old build artifacts'

    builds = Ci::Build.with_artifacts_expired
    builds.find_each(batch_size: 50).each do |build|
      build.erase_artifacts!
    end
  end
end

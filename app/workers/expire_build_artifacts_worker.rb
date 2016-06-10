class ExpireBuildArtifactsWorker
  include Sidekiq::Worker

  def perform
    Rails.logger.info 'Cleaning old build artifacts'

    builds = Ci::Build.with_expired_artifacts
    builds.find_each(batch_size: 50).each do |build|
      Rails.logger.debug "Removing artifacts build #{build.id}..."
      build.erase_artifacts!
    end
  end
end

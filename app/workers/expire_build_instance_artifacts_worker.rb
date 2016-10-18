class ExpireBuildInstanceArtifactsWorker
  include Sidekiq::Worker

  def perform(build_id)
    build = Ci::Build
      .with_expired_artifacts
      .reorder(nil)
      .find_by(id: build_id)

    return unless build.try(:project)

    Rails.logger.info "Removing artifacts for build #{build.id}..."
    build.erase_artifacts!
  end
end

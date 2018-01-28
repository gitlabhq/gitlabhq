class ExpireBuildInstanceArtifactsWorker
  include ApplicationWorker

  def perform(build_id)
    build = Ci::Build
      .with_expired_artifacts
      .reorder(nil)
      .find_by(id: build_id)

    return unless build&.project && !build.project.pending_delete

    Rails.logger.info "Removing artifacts for build #{build.id}..."
    build.erase_artifacts!
  end
end

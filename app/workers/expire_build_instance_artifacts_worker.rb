class ExpireBuildInstanceArtifactsWorker
  include Sidekiq::Worker
  include DedicatedSidekiqQueue

  def perform(build_id)
    build = Ci::Build.with_expired_artifacts.reorder(nil).find_by(id: build_id)
    return unless build

    Rails.logger.info "Removing artifacts build #{build.id}..."
    build.erase_artifacts!
  end
end

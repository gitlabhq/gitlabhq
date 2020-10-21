# frozen_string_literal: true

class ExpireBuildInstanceArtifactsWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  feature_category :continuous_integration
  tags :requires_disk_io

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(build_id)
    build = Ci::Build
      .with_expired_artifacts
      .reorder(nil)
      .find_by(id: build_id)

    return unless build&.project && !build.project.pending_delete

    Gitlab::AppLogger.info("Removing artifacts for build #{build.id}...")
    build.erase_erasable_artifacts!
  end
  # rubocop: enable CodeReuse/ActiveRecord
end

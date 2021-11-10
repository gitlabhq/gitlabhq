# frozen_string_literal: true

class ExpireBuildInstanceArtifactsWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3

  feature_category :build_artifacts

  def perform(build_id)
    # rubocop: disable CodeReuse/ActiveRecord
    build = Ci::Build
      .with_expired_artifacts
      .reorder(nil)
      .find_by_id(build_id)
    # rubocop: enable CodeReuse/ActiveRecord

    return unless build&.project && !build.project.pending_delete

    Gitlab::AppLogger.info("Removing artifacts for build #{build.id}...")
    build.erase_erasable_artifacts!
  end
end

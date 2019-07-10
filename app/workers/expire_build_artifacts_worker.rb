# frozen_string_literal: true

class ExpireBuildArtifactsWorker
  include ApplicationWorker
  include CronjobQueue

  def perform
    if Feature.enabled?(:ci_new_expire_job_artifacts_service, default_enabled: true)
      perform_efficient_artifacts_removal
    else
      perform_legacy_artifacts_removal
    end
  end

  def perform_efficient_artifacts_removal
    Ci::DestroyExpiredJobArtifactsService.new.execute
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def perform_legacy_artifacts_removal
    Rails.logger.info 'Scheduling removal of build artifacts' # rubocop:disable Gitlab/RailsLogger

    build_ids = Ci::Build.with_expired_artifacts.pluck(:id)
    build_ids = build_ids.map { |build_id| [build_id] }

    ExpireBuildInstanceArtifactsWorker.bulk_perform_async(build_ids)
  end
  # rubocop: enable CodeReuse/ActiveRecord
end

class ExpireBuildArtifactsWorker
  include ApplicationWorker
  include CronjobQueue

  def perform
    Rails.logger.info 'Scheduling removal of build artifacts'

    build_ids = Ci::Build.with_expired_artifacts.pluck(:id)
    build_ids = build_ids.map { |build_id| [build_id] }

    ExpireBuildInstanceArtifactsWorker.bulk_perform_async(build_ids)
  end
end

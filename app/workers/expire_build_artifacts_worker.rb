class ExpireBuildArtifactsWorker
  include Sidekiq::Worker

  def perform
    Rails.logger.info 'Scheduling removal of build artifacts'

    build_ids = Ci::Build.with_expired_artifacts.pluck(:id)
    build_ids = build_ids.map { |build_id| [build_id] }

    Sidekiq::Client.push_bulk('class' => ExpireBuildInstanceArtifactsWorker, 'args' => build_ids )
  end
end

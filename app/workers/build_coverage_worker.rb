class BuildCoverageWorker
  include Sidekiq::Worker
  include PipelineQueue

  enqueue_in group: :processing

  def perform(build_id)
    Ci::Build.find_by(id: build_id)&.update_coverage
  end
end

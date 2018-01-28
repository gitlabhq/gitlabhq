class BuildCoverageWorker
  include ApplicationWorker
  include PipelineQueue

  def perform(build_id)
    Ci::Build.find_by(id: build_id)&.update_coverage
  end
end

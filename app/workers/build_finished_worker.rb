class BuildFinishedWorker
  include ApplicationWorker
  include PipelineQueue

  queue_namespace :pipeline_processing

  def perform(build_id)
    Ci::Build.find_by(id: build_id).try do |build|
      BuildTraceSectionsWorker.perform_async(build.id)
      BuildCoverageWorker.new.perform(build.id)
      BuildHooksWorker.new.perform(build.id)
    end
  end
end

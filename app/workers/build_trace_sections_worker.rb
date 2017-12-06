class BuildTraceSectionsWorker
  include ApplicationWorker
  include PipelineQueue

  def perform(build_id)
    Ci::Build.find_by(id: build_id)&.parse_trace_sections!
  end
end

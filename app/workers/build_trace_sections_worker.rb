# frozen_string_literal: true

class BuildTraceSectionsWorker
  include ApplicationWorker
  include PipelineQueue

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(build_id)
    Ci::Build.find_by(id: build_id)&.parse_trace_sections!
  end
  # rubocop: enable CodeReuse/ActiveRecord
end

# frozen_string_literal: true

class BuildTraceSectionsWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker
  include PipelineQueue

  tags :requires_disk_io

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(build_id)
    Ci::Build.find_by(id: build_id)&.parse_trace_sections!
  end
  # rubocop: enable CodeReuse/ActiveRecord
end

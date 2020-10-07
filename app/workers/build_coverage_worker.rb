# frozen_string_literal: true

class BuildCoverageWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker
  include PipelineQueue

  tags :requires_disk_io

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(build_id)
    Ci::Build.find_by(id: build_id)&.update_coverage
  end
  # rubocop: enable CodeReuse/ActiveRecord
end

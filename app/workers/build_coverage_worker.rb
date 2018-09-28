# frozen_string_literal: true

class BuildCoverageWorker
  include ApplicationWorker
  include PipelineQueue

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(build_id)
    Ci::Build.find_by(id: build_id)&.update_coverage
  end
  # rubocop: enable CodeReuse/ActiveRecord
end

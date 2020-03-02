# frozen_string_literal: true

class BuildQueueWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker
  include PipelineQueue

  queue_namespace :pipeline_processing
  feature_category :continuous_integration
  urgency :high
  worker_resource_boundary :cpu

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(build_id)
    Ci::Build.find_by(id: build_id).try do |build|
      Ci::UpdateBuildQueueService.new.execute(build)
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord
end

# frozen_string_literal: true

class BuildQueueWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  sidekiq_options retry: 3
  include PipelineQueue

  queue_namespace :pipeline_processing
  feature_category :continuous_integration
  urgency :high
  worker_resource_boundary :cpu
  data_consistency :sticky

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(build_id)
    Ci::Build.find_by(id: build_id).try do |build|
      Ci::UpdateBuildQueueService.new.tick(build)
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord
end

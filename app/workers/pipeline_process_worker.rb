# frozen_string_literal: true

class PipelineProcessWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  sidekiq_options retry: 3
  include PipelineQueue

  queue_namespace :pipeline_processing
  feature_category :continuous_integration
  urgency :high
  loggable_arguments 1
  data_consistency :delayed, feature_flag: :load_balancing_for_pipeline_process_worker

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(pipeline_id)
    Ci::Pipeline.find_by(id: pipeline_id).try do |pipeline|
      Ci::ProcessPipelineService
        .new(pipeline)
        .execute
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord
end

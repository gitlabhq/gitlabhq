# frozen_string_literal: true

class PipelineProcessWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3
  include PipelineQueue

  queue_namespace :pipeline_processing
  feature_category :continuous_integration
  urgency :high
  loggable_arguments 1

  idempotent!
  deduplicate :until_executing # Remove when FF `ci_pipeline_process_worker_dedup_until_executed` is removed

  def perform(pipeline_id)
    Ci::Pipeline.find_by_id(pipeline_id).try do |pipeline|
      Ci::ProcessPipelineService
        .new(pipeline)
        .execute
    end
  end

  # When FF `ci_pipeline_process_worker_dedup_until_executed` is removed, remove this method and
  # add `deduplicate :until_executed, if_deduplicated: :reschedule_once`, ttl: 1.minute to the class
  def self.perform_async(pipeline_id)
    return super unless Feature.enabled?(:ci_pipeline_process_worker_dedup_until_executed)

    set(
      deduplicate: { strategy: :until_executed, options: { if_deduplicated: :reschedule_once, ttl: 1.minute } }
    ).perform_async(pipeline_id)
  end
end

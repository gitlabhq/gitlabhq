# frozen_string_literal: true

# Deprecated and will be removed in 17.0.
# Use `Environments::StopJobSuccessWorker` instead.
class BuildSuccessWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3
  include PipelineQueue

  queue_namespace :pipeline_processing
  urgency :high

  def perform(build_id); end
end

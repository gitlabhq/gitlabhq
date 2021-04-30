# frozen_string_literal: true

class BuildHooksWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  sidekiq_options retry: 3
  include PipelineQueue

  queue_namespace :pipeline_hooks
  feature_category :continuous_integration
  urgency :high
  data_consistency :delayed, feature_flag: :load_balancing_for_build_hooks_worker

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(build_id)
    Ci::Build.includes({ runner: :tags })
      .find_by(id: build_id)
      .try(:execute_hooks)
  end
  # rubocop: enable CodeReuse/ActiveRecord
end

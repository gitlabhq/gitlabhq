# frozen_string_literal: true

class BuildHooksWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  sidekiq_options retry: 3
  include PipelineQueue

  queue_namespace :pipeline_hooks
  feature_category :continuous_integration
  urgency :high
  data_consistency :delayed

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(build_id)
    build = Ci::Build.find_by_id(build_id)

    build.execute_hooks if build
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def self.perform_async(build)
    Gitlab::AppLogger.info(
      message: "Enqueuing hooks for Build #{build.id}: #{build.status}",
      class: self.name,
      build_id: build.id,
      pipeline_id: build.pipeline_id,
      project_id: build.project_id,
      build_status: build.status)

    super(build.id)
  end
end

# frozen_string_literal: true

class CreatePipelineWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker
  include PipelineQueue

  queue_namespace :pipeline_creation
  feature_category :continuous_integration
  latency_sensitive_worker!
  worker_resource_boundary :cpu

  def perform(project_id, user_id, ref, source, params = {})
    project = Project.find(project_id)
    user = User.find(user_id)
    params = params.deep_symbolize_keys

    Ci::CreatePipelineService
      .new(project, user, ref: ref)
      .execute(source, **params)
  end
end

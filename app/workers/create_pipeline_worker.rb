# frozen_string_literal: true

class CreatePipelineWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :sticky

  sidekiq_options retry: 3
  include PipelineQueue

  queue_namespace :pipeline_creation
  feature_category :pipeline_composition
  urgency :high
  worker_resource_boundary :cpu
  loggable_arguments 2, 3, 4

  def perform(project_id, user_id, ref, source, execute_options = {}, creation_params = {})
    Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/464671')

    project = Project.find(project_id)
    user = User.find(user_id)
    execute_options = execute_options.deep_symbolize_keys
    creation_params = creation_params.symbolize_keys.merge(ref: ref)

    Ci::CreatePipelineService
      .new(project, user, **creation_params)
      .execute(source, **execute_options)
  end
end

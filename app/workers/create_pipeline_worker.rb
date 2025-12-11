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

    project = Project.find_by_id(project_id)
    return unless project

    user = User.find_by_id(user_id)
    return unless user

    execute_options = execute_options.deep_symbolize_keys
    creation_params = creation_params.symbolize_keys.merge(ref: ref)

    response = Ci::CreatePipelineService
      .new(project, user, **creation_params)
      .execute(source, **execute_options)

    log_pipeline_errors(response.message, project, **creation_params) if response.error?
  end

  def log_pipeline_errors(error_message, project, **creation_params)
    data = {
      class: self.class.name,
      correlation_id: Labkit::Correlation::CorrelationId.current_id.to_s,
      project_id: project.id,
      project_path: project.full_path,
      message: "Error creating pipeline",
      errors: error_message,
      pipeline_params: sanitized_pipeline_params(**creation_params)
    }

    Sidekiq.logger.warn(data)
  end

  def sanitized_pipeline_params(**creation_params)
    creation_params.except(:push_options, :pipeline_creation_request)
  end
end

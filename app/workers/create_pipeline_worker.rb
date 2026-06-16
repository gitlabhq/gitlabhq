# frozen_string_literal: true

class CreatePipelineWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker
  include PipelineQueue

  data_consistency :sticky

  sidekiq_options retry: 3

  sidekiq_retries_exhausted do |job, exception|
    project_id, _user_id, ref, _source, _execute_options, creation_params = job['args']

    new.perform_failure(project_id, ref, exception, creation_params.to_h)
  end

  queue_namespace :pipeline_creation
  feature_category :pipeline_composition
  urgency :high
  worker_resource_boundary :cpu
  loggable_arguments 2, 3, 4

  # Raised when a pipeline creation fails due to a ref not being found.
  # This can be a user error, but is also known to happen
  # transiently on Praefect-backed storage due to replication delay.
  ReferenceNotFoundError = Class.new(::Gitlab::SidekiqMiddleware::RetryError)

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

    return unless response.error?

    raise_reference_not_found_error!(response, project, **creation_params)
    log_pipeline_errors(response.message, project, **creation_params)
  end

  def perform_failure(project_id, ref, exception, creation_params = {})
    project = Project.find_by_id(project_id)
    return unless project

    creation_params = creation_params.symbolize_keys.merge(ref: ref)

    log_pipeline_errors(exception.message, project, **creation_params)
  end

  private

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

  def raise_reference_not_found_error!(response, project, **creation_params)
    return unless Feature.enabled?(:ci_create_pipeline_worker_retry_on_reference_not_found, project)
    return unless response.message == Gitlab::Ci::Pipeline::Chain::Validate::Repository::REFERENCE_NOT_FOUND_MESSAGE
    return unless Gitlab::Git.blank_ref?(creation_params[:before].to_s)

    raise ReferenceNotFoundError, 'Reference not found'
  end
end

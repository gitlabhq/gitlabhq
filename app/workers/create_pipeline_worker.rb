# frozen_string_literal: true

class CreatePipelineWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker
  include PipelineQueue

  data_consistency :sticky

  sidekiq_options retry: 3

  # Only the push path of this worker is in the create_pipeline_from_commit SLI. The GraphQL
  # pipelineCreate mutation also enqueues it (source merge_request_event with mergeRequestIid,
  # else api/web), and those API creations are out of scope.
  EXPERIENCE_SOURCE = 'push'

  sidekiq_retries_exhausted do |job, exception|
    project_id, _user_id, ref, source, _execute_options, creation_params = job['args']

    if report_experience?(source)
      Ci::PipelineCreation::ExperienceReporter.report_error(
        source: source,
        started_at: creation_params.to_h.dig('pipeline_creation_request', 'started_at'),
        project_id: project_id
      )
    end

    new.perform_failure(project_id, ref, exception, creation_params.to_h)
  end

  queue_namespace :pipeline_creation
  feature_category :pipeline_composition
  urgency :high
  worker_resource_boundary :cpu
  loggable_arguments 2, 3, 4

  # Raised when pipeline creation fails due to a transient Gitaly read during a
  # read-after-write window: the ref pointer or the commit it points at is not yet
  # visible on the node serving the read. This can be a user error, but is also known
  # to happen transiently on Praefect-backed storage due to replication delay.
  # Retried via Sidekiq (retry: 3) so the pipeline self-heals once Gitaly is consistent.
  TransientGitalyReadError = Class.new(::Gitlab::SidekiqMiddleware::RetryError)

  def self.report_experience?(source)
    source.to_s == EXPERIENCE_SOURCE
  end

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

    raise_transient_gitaly_read_error!(response, project, **creation_params) if response.error?

    if self.class.report_experience?(source)
      Ci::PipelineCreation::ExperienceReporter.report(
        pipeline: response.payload,
        source: source,
        started_at: creation_params.with_indifferent_access.dig(:pipeline_creation_request, :started_at)
      )
    end

    return unless response.error?

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

  def raise_transient_gitaly_read_error!(response, project, **creation_params)
    raise_on_reference_not_found!(response, **creation_params)
    raise_on_commit_not_found!(response, project)
  end

  def raise_on_reference_not_found!(response, **creation_params)
    return unless response.message == Gitlab::Ci::Pipeline::Chain::Validate::Repository::REFERENCE_NOT_FOUND_MESSAGE
    return unless Gitlab::Git.blank_ref?(creation_params[:before].to_s)

    raise TransientGitalyReadError, Gitlab::Ci::Pipeline::Chain::Validate::Repository::REFERENCE_NOT_FOUND_MESSAGE
  end

  def raise_on_commit_not_found!(response, project)
    return unless Feature.enabled?(:ci_create_pipeline_worker_retry_on_commit_not_found, project)
    return unless response.message == Gitlab::Ci::Pipeline::Chain::Validate::Repository::COMMIT_NOT_FOUND_MESSAGE

    raise TransientGitalyReadError, Gitlab::Ci::Pipeline::Chain::Validate::Repository::COMMIT_NOT_FOUND_MESSAGE
  end
end

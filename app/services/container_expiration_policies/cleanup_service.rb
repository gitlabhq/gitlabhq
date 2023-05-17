# frozen_string_literal: true

module ContainerExpirationPolicies
  class CleanupService
    attr_reader :repository

    SERVICE_RESULT_FIELDS = %i[original_size before_truncate_size after_truncate_size before_delete_size deleted_size cached_tags_count].freeze

    def initialize(repository)
      @repository = repository
    end

    def execute
      return ServiceResponse.error(message: 'no repository') unless repository

      unless policy.valid?
        disable_policy!

        return ServiceResponse.error(message: 'invalid policy')
      end

      schedule_next_run_if_needed

      begin
        service_result = Projects::ContainerRepository::CleanupTagsService
                           .new(container_repository: repository, params: policy_params.merge('container_expiration_policy' => true))
                           .execute
      rescue StandardError
        repository.cleanup_unfinished!

        raise
      end

      if service_result[:status] == :success
        repository.update!(
          expiration_policy_cleanup_status: :cleanup_unscheduled,
          expiration_policy_completed_at: Time.zone.now,
          last_cleanup_deleted_tags_count: service_result[:deleted_size]
        )

        success(:finished, service_result)
      else
        repository.cleanup_unfinished!

        success(:unfinished, service_result)
      end
    end

    private

    def schedule_next_run_if_needed
      return if policy.next_run_at.future?

      repos_before_next_run = ::ContainerRepository.for_project_id(policy.project_id)
                                                   .expiration_policy_started_at_nil_or_before(policy.next_run_at)
      return if repos_before_next_run.exists?

      policy.schedule_next_run!
    end

    def disable_policy!
      policy.disable!
      repository.cleanup_unscheduled!

      Gitlab::ErrorTracking.log_exception(
        ::ContainerExpirationPolicyWorker::InvalidPolicyError.new,
        container_expiration_policy_id: policy.id
      )
    end

    def success(cleanup_status, service_result)
      payload = {
        cleanup_status: cleanup_status,
        container_repository_id: repository.id
      }

      SERVICE_RESULT_FIELDS.each do |field|
        payload["cleanup_tags_service_#{field}".to_sym] = service_result[field]
      end

      ServiceResponse.success(message: "cleanup #{cleanup_status}", payload: payload)
    end

    def policy_params
      return {} unless policy

      policy.policy_params
    end

    def policy
      project.container_expiration_policy
    end

    def project
      repository&.project
    end
  end
end

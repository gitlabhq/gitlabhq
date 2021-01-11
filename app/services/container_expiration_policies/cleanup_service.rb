# frozen_string_literal: true

module ContainerExpirationPolicies
  class CleanupService
    attr_reader :repository

    SERVICE_RESULT_FIELDS = %i[original_size before_truncate_size after_truncate_size before_delete_size].freeze

    def initialize(repository)
      @repository = repository
    end

    def execute
      return ServiceResponse.error(message: 'no repository') unless repository

      repository.start_expiration_policy!

      service_result = Projects::ContainerRepository::CleanupTagsService
        .new(project, nil, policy_params.merge('container_expiration_policy' => true))
        .execute(repository)

      if service_result[:status] == :success
        repository.update!(
          expiration_policy_cleanup_status: :cleanup_unscheduled,
          expiration_policy_started_at: nil,
          expiration_policy_completed_at: Time.zone.now
        )
        success(:finished, service_result)
      else
        repository.cleanup_unfinished!

        success(:unfinished, service_result)
      end
    end

    private

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

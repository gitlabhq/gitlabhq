# frozen_string_literal: true

module ContainerExpirationPolicies
  class CleanupService
    attr_reader :repository

    def initialize(repository)
      @repository = repository
    end

    def execute
      return ServiceResponse.error(message: 'no repository') unless repository

      repository.start_expiration_policy!

      result = Projects::ContainerRepository::CleanupTagsService
        .new(project, nil, policy_params.merge('container_expiration_policy' => true))
        .execute(repository)

      if result[:status] == :success
        repository.update!(
          expiration_policy_cleanup_status: :cleanup_unscheduled,
          expiration_policy_started_at: nil
        )
        success(:finished)
      else
        repository.cleanup_unfinished!

        success(:unfinished)
      end
    end

    private

    def success(cleanup_status)
      ServiceResponse.success(message: "cleanup #{cleanup_status}", payload: { cleanup_status: cleanup_status, container_repository_id: repository.id })
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

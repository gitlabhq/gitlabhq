# frozen_string_literal: true

module Deployable
  extend ActiveSupport::Concern

  included do
    after_create :create_deployment

    def create_deployment
      return unless starts_environment? && !has_deployment?

      environment = project.environments.find_or_create_by(
        name: expanded_environment_name
      )

      # If we failed to persist envirionment record by validation error, such as name with invalid character,
      # the job will fall back to a non-environment job.
      return unless environment.persisted?

      create_deployment!(
        cluster_id: environment.deployment_platform&.cluster_id,
        project_id: environment.project_id,
        environment: environment,
        ref: ref,
        tag: tag,
        sha: sha,
        user: user,
        on_stop: on_stop)
    end
  end
end

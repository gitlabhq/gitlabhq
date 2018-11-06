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

      environment.deployments.create!(
        project_id: environment.project_id,
        environment: environment,
        ref: ref,
        tag: tag,
        sha: sha,
        user: user,
        deployable: self,
        on_stop: on_stop).tap do |_|
        self.reload # Reload relationships
      end
    end
  end
end

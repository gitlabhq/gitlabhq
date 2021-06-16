# frozen_string_literal: true

module Deployments
  class UpdateEnvironmentService
    attr_reader :deployment
    attr_reader :deployable

    delegate :environment, to: :deployment
    delegate :variables, to: :deployable
    delegate :options, to: :deployable, allow_nil: true

    EnvironmentUpdateFailure = Class.new(StandardError)

    def initialize(deployment)
      @deployment = deployment
      @deployable = deployment.deployable
    end

    def execute
      deployment.create_ref
      deployment.invalidate_cache

      update_environment(deployment)

      deployment
    end

    def update_environment(deployment)
      ActiveRecord::Base.transaction do
        # Renew attributes at update
        renew_external_url
        renew_auto_stop_in
        renew_deployment_tier
        environment.fire_state_event(action)

        if environment.save
          deployment.update_merge_request_metrics! unless environment.stopped?
        else
          # If there is a validation error on environment update, such as
          # the external URL is malformed, the error message is recorded for debugging purpose.
          # We should surface the error message to users for letting them to take an action.
          # See https://gitlab.com/gitlab-org/gitlab/-/issues/21182.
          Gitlab::ErrorTracking.track_exception(
            EnvironmentUpdateFailure.new,
            project_id: deployment.project_id,
            environment_id: environment.id,
            reason: environment.errors.full_messages.to_sentence)
        end
      end
    end

    private

    def environment_options
      options&.dig(:environment) || {}
    end

    def expanded_environment_url
      ExpandVariables.expand(environment_url, -> { variables }) if environment_url
    end

    def environment_url
      environment_options[:url]
    end

    def action
      environment_options[:action] || 'start'
    end

    def renew_external_url
      if (url = expanded_environment_url)
        environment.external_url = url
      end
    end

    def renew_auto_stop_in
      return unless deployable

      environment.auto_stop_in = deployable.environment_auto_stop_in
    end

    def renew_deployment_tier
      return unless deployable

      if (tier = deployable.environment_deployment_tier)
        environment.tier = tier
      end
    end
  end
end

Deployments::UpdateEnvironmentService.prepend_mod_with('Deployments::UpdateEnvironmentService')

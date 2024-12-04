# frozen_string_literal: true

module Deployments
  class UpdateEnvironmentService
    include Gitlab::Utils::StrongMemoize

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
      ApplicationRecord.transaction do
        # Renew attributes at update
        renew_external_url
        renew_auto_stop_in
        renew_deployment_tier
        renew_cluster_agent
        renew_kubernetes_namespace
        renew_flux_resource_path
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
      return unless environment_url

      ExpandVariables.expand(environment_url, -> { variables.sort_and_expand_all })
    end

    def expanded_cluster_agent_path
      return unless cluster_agent_path

      ExpandVariables.expand(cluster_agent_path, -> { variables.sort_and_expand_all })
    end

    def environment_url
      environment_options[:url]
    end

    def action
      environment_options[:action] || 'start'
    end

    def cluster_agent_path
      environment_options.dig(:kubernetes, :agent)
    end

    def kubernetes_namespace
      deployable&.expanded_kubernetes_namespace
    end

    def flux_resource_path
      environment_options.dig(:kubernetes, :flux_resource_path)
    end

    def renew_external_url
      if (url = expanded_environment_url)
        environment.external_url = url
      end
    end

    def renew_auto_stop_in
      return unless deployable

      if (value = deployable.expanded_auto_stop_in)
        environment.auto_stop_in = value
      end
    end

    def renew_deployment_tier
      return unless deployable

      if (tier = deployable.environment_tier_from_options)
        environment.tier = tier
      end
    end

    def renew_cluster_agent
      return unless requested_agent_authorized?

      environment.cluster_agent = matching_authorization.agent
    end

    def user_access_authorizations_for_project
      Clusters::Agents::Authorizations::UserAccess::Finder.new(deployable.user, project: deployable.project).execute
    end

    def renew_kubernetes_namespace
      return unless requested_agent_authorized?

      environment.kubernetes_namespace = kubernetes_namespace if kubernetes_namespace
    end

    def renew_flux_resource_path
      return unless requested_agent_authorized? && kubernetes_namespace

      environment.flux_resource_path = flux_resource_path if flux_resource_path
    end

    def requested_agent_authorized?
      matching_authorization.present?
    end

    def matching_authorization
      return false unless cluster_agent_path && deployable.user

      requested_project_path, requested_agent_name = expanded_cluster_agent_path.split(':')

      user_access_authorizations_for_project.find do |authorization|
        requested_project_path == authorization.config_project.full_path &&
          requested_agent_name == authorization.agent.name
      end
    end
    strong_memoize_attr :matching_authorization
  end
end

Deployments::UpdateEnvironmentService.prepend_mod_with('Deployments::UpdateEnvironmentService')

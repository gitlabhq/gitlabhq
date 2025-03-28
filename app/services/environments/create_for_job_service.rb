# frozen_string_literal: true

module Environments
  # This class creates an environment record for a pipeline job.
  class CreateForJobService
    def execute(job)
      return unless job.is_a?(::Ci::Processable) && job.has_environment_keyword?

      environment = to_resource(job)

      if environment.persisted?
        job.persisted_environment = environment
        job.assign_attributes(metadata_attributes: { expanded_environment_name: environment.name })
      else
        job.assign_attributes(status: :failed, failure_reason: :environment_creation_failure)
      end

      environment
    end

    private

    # rubocop: disable Performance/ActiveRecordSubtransactionMethods
    def to_resource(job)
      environment = job.project.environments
                       .safe_find_or_create_by(name: job.expanded_environment_name) do |environment|
        # Initialize the attributes at creation
        environment.auto_stop_in = expanded_auto_stop_in(job)
        environment.tier = job.environment_tier_from_options
        environment.merge_request = job.pipeline.merge_request
      end

      if resource_management_feature_enabled?(job) && environment.cluster_agent.nil?
        authorization = matching_authorization(job)
        if authorization && authorization.agent.resource_management_enabled?
          environment.update(cluster_agent: authorization.agent)
        end
      end

      environment
    end
    # rubocop: enable Performance/ActiveRecordSubtransactionMethods

    def expanded_auto_stop_in(job)
      return unless job.environment_auto_stop_in

      ExpandVariables.expand(job.environment_auto_stop_in, -> { job.simple_variables.sort_and_expand_all })
    end

    def cluster_agent_path(job)
      environment_options(job).dig(:kubernetes, :agent)
    end

    def environment_options(job)
      job.options&.dig(:environment) || {}
    end

    def matching_authorization(job)
      return false unless cluster_agent_path(job)

      requested_project_path, requested_agent_name = expanded_cluster_agent_path(job).split(':')

      ci_access_authorizations_for_project(job).find do |authorization|
        requested_project_path == authorization.config_project.full_path &&
          requested_agent_name == authorization.agent.name &&
          authorization.config.dig('resource_management', 'enabled') == true
      end
    end

    def ci_access_authorizations_for_project(job)
      Clusters::Agents::Authorizations::CiAccess::Finder.new(job.project).execute
    end

    def expanded_cluster_agent_path(job)
      return unless cluster_agent_path(job)

      ExpandVariables.expand(cluster_agent_path(job), -> { job.simple_variables.sort_and_expand_all })
    end

    def resource_management_feature_enabled?(job)
      ::Feature.enabled?(:gitlab_managed_cluster_resources, job.project)
    end
  end
end

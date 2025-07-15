# frozen_string_literal: true

module Atlassian
  module JiraConnect
    module Serializers
      class DeploymentEntity < Grape::Entity
        include Gitlab::Routing
        include Gitlab::Utils::StrongMemoize

        COMMITS_LIMIT = 2000
        ISSUE_KEY_LIMIT = 500
        ASSOCIATION_LIMIT = 500

        format_with(:iso8601, &:iso8601)

        expose :schema_version, as: :schemaVersion
        expose :iid, as: :deploymentSequenceNumber
        expose :update_sequence_id, as: :updateSequenceNumber
        expose :display_name, as: :displayName
        expose :description
        expose :associations
        expose :url
        expose :label
        expose :state
        expose :updated_at, as: :lastUpdated, format_with: :iso8601
        expose :pipeline_entity, as: :pipeline
        expose :environment_entity, as: :environment
        expose :generate_deployment_commands_from_integration_configuration, as: :commands

        def issue_keys
          @issue_keys ||= (issue_keys_from_pipeline + issue_keys_from_commits_since_last_deploy)
            .uniq.first(ISSUE_KEY_LIMIT)
        end

        def associations
          keys = issue_keys
          commits = commits_since_last_deploy.first(ASSOCIATION_LIMIT)
          merge_requests = deployment.deployment_merge_requests.first(ASSOCIATION_LIMIT)
          repository_id = project.id.to_s

          combined_associations = service_ids_from_integration_configuration
          combined_associations << { associationType: :issueKeys, values: keys } if keys.present?

          # Add commit as associations
          if commits.present?
            commit_objects = commits.map { |commit| { commitHash: commit.id, repositoryId: repository_id } }
            combined_associations << { associationType: :commit, values: commit_objects }
          end

          # Add merge requests as associations
          if merge_requests.present?
            mr_objects = merge_requests.map do |mr|
              { pullRequestId: mr.merge_request_id, repositoryId: repository_id }
            end
            combined_associations << { associationType: 'pull-request', values: mr_objects }
          end

          combined_associations.presence
        end
        strong_memoize_attr :associations

        private

        delegate :project, :deployable, :environment, :iid, :ref, :short_sha, to: :object
        alias_method :deployment, :object
        alias_method :build, :deployable

        def display_name
          "Deployment #{iid} (#{ref}@#{short_sha}) to #{environment.name}"
        end

        def label
          "#{project.full_path}-#{environment.name}-#{iid}-#{short_sha}"
        end

        def description
          "Deployment #{deployment.iid} (deployment-#{deployment.id}) of #{project.name} (project-#{project.id})
          at #{short_sha} (#{build&.name}) to #{environment.name}"
        end

        def url
          # There is no controller action to show a single deployment, so we
          # link to the build instead
          project_job_url(project, build) if build
        end

        def state
          case deployment.status
          when 'created' then 'pending'
          when 'blocked' then 'pending'
          when 'running' then 'in_progress'
          when 'success' then 'successful'
          when 'failed' then 'failed'
          when 'canceled', 'skipped' then 'cancelled'
          else
            'unknown'
          end
        end

        def schema_version
          '1.0'
        end

        def pipeline_entity
          PipelineEntity.new(build.pipeline) if pipeline?
        end

        def environment_entity
          EnvironmentEntity.new(environment)
        end

        def update_sequence_id
          options[:update_sequence_id] || Client.generate_update_sequence_id
        end

        def pipeline?
          build&.pipeline.present?
        end

        def issue_keys_from_pipeline
          return [] unless pipeline?

          BuildEntity.new(build.pipeline).issue_keys
        end

        # Extract Jira issue keys from commits made to the deployment's branch or tag
        # since the last successful deployment was made to the environment.
        def issue_keys_from_commits_since_last_deploy
          commits = commits_since_last_deploy.without_merge_commits

          commits.flat_map do |commit|
            JiraIssueKeyExtractor.new(commit.message).issue_keys
          end.compact
        end

        def service_ids_from_integration_configuration
          return [] unless project.jira_cloud_app_integration&.active
          return [] if project.jira_cloud_app_integration&.jira_cloud_app_service_ids.blank?

          service_ids = project.jira_cloud_app_integration.jira_cloud_app_service_ids.gsub(/\s+/, '').split(',')
          [{ associationType: 'serviceIdOrKeys', values: service_ids }]
        end

        def generate_deployment_commands_from_integration_configuration
          jira_cloud_app_integration = project.jira_cloud_app_integration

          return unless jira_cloud_app_integration&.active
          return unless jira_cloud_app_integration.jira_cloud_app_enable_deployment_gating
          return if jira_cloud_app_integration.jira_cloud_app_deployment_gating_environments.blank?

          environments = jira_cloud_app_integration.jira_cloud_app_deployment_gating_environments.split(',')
          current_environment = environment.tier

          return unless environments.include?(current_environment)
          return unless state == "pending"

          [{ command: 'initiate_deployment_gating' }]
        end

        def commits_since_last_deploy
          last_deployed_commit = environment
                                     .successful_deployments
                                     .id_not_in(deployment.id)
                                     .ordered
                                     .first
                                     &.commit

          commit_range = if last_deployed_commit
                           "#{last_deployed_commit.id}..#{deployment.commit.id}"
                         else
                           deployment.commit.id
                         end

          project.repository.commits(
            commit_range,
            skip_merges: false,
            limit: COMMITS_LIMIT
          )
        end
        strong_memoize_attr :commits_since_last_deploy
      end
    end
  end
end

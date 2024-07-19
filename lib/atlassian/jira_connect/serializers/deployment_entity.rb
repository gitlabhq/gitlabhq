# frozen_string_literal: true

module Atlassian
  module JiraConnect
    module Serializers
      class DeploymentEntity < Grape::Entity
        include Gitlab::Routing
        include Gitlab::Utils::StrongMemoize

        COMMITS_LIMIT = 5_000

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

        def issue_keys
          @issue_keys ||= (issue_keys_from_pipeline + issue_keys_from_commits_since_last_deploy).uniq
        end

        def associations
          keys = issue_keys

          combined_associations = service_ids_from_integration_configuration
          combined_associations << { associationType: :issueKeys, values: keys } if keys.present?
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
          unless Feature.enabled?(:enable_jira_connect_configuration) # rubocop:disable Gitlab/FeatureFlagWithoutActor -- flag must be global
            return "Deployment #{deployment.iid} of #{project.name} at #{short_sha} (#{build&.name}) to
             #{environment.name}"
          end

          "Deployment #{deployment.iid} of #{project.name} (project-#{project.id})
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
          last_deployed_commit = environment
            .successful_deployments
            .id_not_in(deployment.id)
            .ordered
            .find_by_ref(deployment.ref)
            &.commit

          commits = project.repository.commits(
            deployment.ref,
            before: deployment.commit.created_at,
            after: last_deployed_commit&.created_at,
            skip_merges: true,
            limit: COMMITS_LIMIT
          )

          # Include this deploy's commit, as the `before:` param in `Repository#list_commits_by` excluded it.
          commits << deployment.commit

          commits.flat_map do |commit|
            JiraIssueKeyExtractor.new(commit.message).issue_keys
          end.compact
        end

        def service_ids_from_integration_configuration
          return [] unless Feature.enabled?(:enable_jira_connect_configuration) # rubocop:disable Gitlab/FeatureFlagWithoutActor -- flag must be global
          return [] unless project.jira_cloud_app_integration&.active
          return [] if project.jira_cloud_app_integration&.jira_cloud_app_service_ids.blank?

          service_ids = project.jira_cloud_app_integration.jira_cloud_app_service_ids.gsub(/\s+/, '').split(',')
          [{ associationType: 'serviceIdOrKeys', values: service_ids }]
        end
      end
    end
  end
end

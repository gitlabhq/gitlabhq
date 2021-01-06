# frozen_string_literal: true

module Atlassian
  module JiraConnect
    module Serializers
      class DeploymentEntity < Grape::Entity
        include Gitlab::Routing

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
          return [] unless build&.pipeline.present?

          @issue_keys ||= BuildEntity.new(build.pipeline).issue_keys
        end

        private

        delegate :project, :deployable, :environment, :iid, :ref, :short_sha, to: :object
        alias_method :deployment, :object
        alias_method :build, :deployable

        def associations
          keys = issue_keys

          [{ associationType: :issueKeys, values: keys }] if keys.present?
        end

        def display_name
          "Deployment #{iid} (#{ref}@#{short_sha}) to #{environment.name}"
        end

        def label
          "#{project.full_path}-#{environment.name}-#{iid}-#{short_sha}"
        end

        def description
          "Deployment #{deployment.iid} of #{project.name} at #{short_sha} (#{build&.name}) to #{environment.name}"
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
          PipelineEntity.new(build.pipeline) if build&.pipeline.present?
        end

        def environment_entity
          EnvironmentEntity.new(environment)
        end

        def update_sequence_id
          options[:update_sequence_id] || Client.generate_update_sequence_id
        end
      end
    end
  end
end

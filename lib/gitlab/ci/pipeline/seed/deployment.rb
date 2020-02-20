# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Seed
        class Deployment < Seed::Base
          attr_reader :job, :environment

          def initialize(job)
            @job = job
            @environment = Seed::Environment.new(@job)
          end

          def to_resource
            return job.deployment if job.deployment
            return unless job.starts_environment?

            deployment = ::Deployment.new(attributes)
            deployment.environment = environment.to_resource

            # If there is a validation error on environment creation, such as
            # the name contains invalid character, the job will fall back to a
            # non-environment job.
            return unless deployment.valid? && deployment.environment.persisted?

            if cluster_id = deployment.environment.deployment_platform&.cluster_id
              # double write cluster_id until 12.9: https://gitlab.com/gitlab-org/gitlab/issues/202628
              deployment.cluster_id = cluster_id
              deployment.deployment_cluster = ::DeploymentCluster.new(
                cluster_id: cluster_id,
                kubernetes_namespace: deployment.environment.deployment_namespace
              )
            end

            # Allocate IID for deployments.
            # This operation must be outside of transactions of pipeline creations.
            deployment.ensure_project_iid!

            deployment
          end

          private

          def attributes
            {
              project: job.project,
              user: job.user,
              ref: job.ref,
              tag: job.tag,
              sha: job.sha,
              on_stop: job.on_stop
            }
          end
        end
      end
    end
  end
end

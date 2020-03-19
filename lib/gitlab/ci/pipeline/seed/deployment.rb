# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Seed
        class Deployment < Seed::Base
          attr_reader :job, :environment

          def initialize(job, environment)
            @job = job
            @environment = environment
          end

          def to_resource
            return job.deployment if job.deployment
            return unless job.starts_environment?

            deployment = ::Deployment.new(attributes)

            # If there is a validation error on environment creation, such as
            # the name contains invalid character, the job will fall back to a
            # non-environment job.
            return unless deployment.valid? && deployment.environment.persisted?

            if cluster = deployment.environment.deployment_platform&.cluster
              # double write cluster_id until 12.9: https://gitlab.com/gitlab-org/gitlab/issues/202628
              deployment.cluster_id = cluster.id
              deployment.deployment_cluster = ::DeploymentCluster.new(
                cluster_id: cluster.id,
                kubernetes_namespace: cluster.kubernetes_namespace_for(deployment.environment, deployable: job)
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
              environment: environment,
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

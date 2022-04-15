# frozen_string_literal: true

module Gitlab
  module DataBuilder
    module Deployment
      extend self

      def build(deployment, status_changed_at)
        # Deployments will not have a deployable when created using the API.
        deployable_url =
          if deployment.deployable
            Gitlab::UrlBuilder.build(deployment.deployable)
          end

        commit_url =
          if (commit = deployment.commit)
            Gitlab::UrlBuilder.build(commit)
          end

        user_url =
          if deployment.deployed_by
            Gitlab::UrlBuilder.build(deployment.deployed_by)
          end

        {
          object_kind: 'deployment',
          status: deployment.status,
          status_changed_at: status_changed_at,
          deployment_id: deployment.id,
          deployable_id: deployment.deployable_id,
          deployable_url: deployable_url,
          environment: deployment.environment.name,
          project: deployment.project.hook_attrs,
          short_sha: deployment.short_sha,
          user: deployment.deployed_by&.hook_attrs,
          user_url: user_url,
          commit_url: commit_url,
          commit_title: deployment.commit_title,
          ref: deployment.ref
        }
      end
    end
  end
end

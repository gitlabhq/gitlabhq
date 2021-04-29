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

        {
          object_kind: 'deployment',
          status: deployment.status,
          status_changed_at: status_changed_at,
          deployable_id: deployment.deployable_id,
          deployable_url: deployable_url,
          environment: deployment.environment.name,
          project: deployment.project.hook_attrs,
          short_sha: deployment.short_sha,
          user: deployment.deployed_by.hook_attrs,
          user_url: Gitlab::UrlBuilder.build(deployment.deployed_by),
          commit_url: Gitlab::UrlBuilder.build(deployment.commit),
          commit_title: deployment.commit.title
        }
      end
    end
  end
end

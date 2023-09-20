# frozen_string_literal: true

module Gitlab
  module DataBuilder
    module Deployment
      extend self

      # NOTE: Time-sensitive attributes should be explicitly passed as argument instead of reading from database.
      def build(deployment, status, status_changed_at)
        # Deployments will not have a deployable when created using the API.
        deployable_url =
          if deployment.deployable.instance_of?(::Ci::Build)
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

        # `status` argument could be `nil` during the upgrade. We can remove `deployment.status` in GitLab 15.5.
        # See https://docs.gitlab.com/ee/development/multi_version_compatibility.html for more info.
        deployment_status = status || deployment.status

        {
          object_kind: 'deployment',
          status: deployment_status,
          status_changed_at: status_changed_at,
          deployment_id: deployment.id,
          deployable_id: deployment.deployable_id,
          deployable_url: deployable_url,
          environment: deployment.environment.name,
          environment_tier: deployment.environment.tier,
          environment_slug: deployment.environment.slug,
          environment_external_url: deployment.environment.external_url,
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

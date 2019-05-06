# frozen_string_literal: true

module Gitlab
  module DataBuilder
    module Deployment
      extend self

      def build(deployment)
        {
          object_kind: 'deployment',
          status: deployment.status,
          deployable_id: deployment.deployable_id,
          deployable_url: Gitlab::UrlBuilder.build(deployment.deployable),
          environment: deployment.environment.name,
          project: deployment.project.hook_attrs,
          short_sha: deployment.short_sha,
          user: deployment.user.hook_attrs,
          user_url: Gitlab::UrlBuilder.build(deployment.user),
          commit_url: Gitlab::UrlBuilder.build(deployment.commit),
          commit_title: deployment.commit.title
        }
      end
    end
  end
end

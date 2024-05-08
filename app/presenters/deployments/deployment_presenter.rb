# frozen_string_literal: true

module Deployments
  class DeploymentPresenter < Gitlab::View::Presenter::Delegated
    presents ::Deployment, as: :deployment

    delegator_override :tags

    # Note: this returns the path key as 'tags/tag_name' but it is used as a URL in the UI

    def tags
      super.map do |tag|
        name = tag.delete_prefix(Gitlab::Git::TAG_REF_PREFIX)
        {
          name: name,
          path: tag.delete_prefix('refs/'),
          web_path: project_tag_path(project, id: name)
        }
      end
    end

    delegator_override :ref_path
    def ref_path
      project_tree_path(project, id: ref)
    end

    def web_path
      project_environment_deployment_path(project, environment, deployment)
    end
  end
end

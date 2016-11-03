class DeploymentEntity < Grape::Entity
  include RequestAwareEntity

  expose :id
  expose :iid
  expose :sha

  expose :ref do
    expose :name do |deployment|
      deployment.ref
    end

    expose :ref_url do |deployment|
      @urls.namespace_project_tree_url(
        deployment.project.namespace,
        deployment.project,
        id: deployment.ref)
    end
  end

  expose :tag
  expose :last?
  expose :user, using: API::Entities::UserBasic
  expose :commit, using: CommitEntity
  expose :deployable, using: BuildEntity
  expose :manual_actions
end

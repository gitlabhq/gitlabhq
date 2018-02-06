class DeploymentEntity < Grape::Entity
  include RequestAwareEntity

  expose :id
  expose :iid
  expose :sha

  expose :ref do
    expose :name do |deployment|
      deployment.ref
    end

    expose :ref_path do |deployment|
      project_tree_path(deployment.project, id: deployment.ref)
    end
  end

  expose :created_at
  expose :tag
  expose :last?

  expose :user, using: UserEntity
  expose :commit, using: CommitEntity
  expose :deployable, using: JobEntity
  expose :manual_actions, using: JobEntity
end

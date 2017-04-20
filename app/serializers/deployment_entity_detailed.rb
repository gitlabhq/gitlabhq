class DeploymentEntityDetailed < DeploymentEntity
  expose :ref do
    expose :ref_path do |deployment|
      namespace_project_tree_path(
        deployment.project.namespace,
        deployment.project,
        id: deployment.ref)
    end
  end

  expose :user, using: UserEntity
  expose :commit, using: CommitEntity
  expose :deployable, using: BuildEntity
  expose :manual_actions, using: BuildEntity
end

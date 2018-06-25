class DeployKeysProjectEntity < Grape::Entity
  expose :can_push
  expose :project, using: ProjectEntity
end

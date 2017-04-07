class DeployKeyEntity < Grape::Entity
  expose :id
  expose :user_id
  expose :title
  expose :fingerprint
  expose :can_push
  expose :destroyed_when_orphaned?, as: :destroyed_when_orphaned
  expose :almost_orphaned?, as: :almost_orphaned
  expose :created_at
  expose :updated_at
  expose :projects, using: ProjectEntity do |deploy_key|
    deploy_key.projects.select { |project| options[:user].can?(:read_project, project) }
  end
end

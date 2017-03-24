class DeployKeyEntity < Grape::Entity
  expose :id
  expose :user_id
  expose :title
  expose :fingerprint
  expose :can_push
  expose :created_at
  expose :updated_at
  expose :projects, using: ProjectEntity do |deploy_key|
    deploy_key.projects.select { |project| options[:user].can?(:read_project, project) }
  end
end

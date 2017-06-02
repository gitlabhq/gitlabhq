class ProjectEntity < Grape::Entity
  include RequestAwareEntity
  
  expose :id
  expose :name

  expose :full_path do |project|
    namespace_project_path(project.namespace, project)
  end

  expose :full_name do |project|
    project.full_name
  end
end

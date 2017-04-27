class ProjectEntity < Grape::Entity
  expose :id
  expose :name

  expose :full_path do |project|
    project.full_path
  end

  expose :full_name do |project|
    project.full_name
  end
end

class ProjectEntity < Grape::Entity
  expose :id
  expose :name

  expose :test do |project|
    'something'
  end
end

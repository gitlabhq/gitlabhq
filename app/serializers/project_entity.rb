class ProjectEntity < Grape::Entity
  include RequestAwareEntity

  expose :id
  expose :name

  expose :test do |project|
    request.user.email
  end
end

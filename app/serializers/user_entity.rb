class UserEntity < API::Entities::UserBasic
  include RequestAwareEntity

  expose :can_fork do |user|
    can?(user, :fork_project, request.project) if project
  end

  expose :can_create_merge_request do |user|
    can?(user, :create_merge_request_in, project) if project
  end

  expose :path do |user|
    user_path(user)
  end

  def project
    return false unless request.respond_to?(:project) && request.project

    request.project
  end
end

class UserEntity < API::Entities::UserBasic
  include RequestAwareEntity

  unexpose :web_url

  expose :path do |user|
    user_path(user)
  end
end

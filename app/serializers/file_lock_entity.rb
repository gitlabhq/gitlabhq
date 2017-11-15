class FileLockEntity < Grape::Entity
  expose :user, using: API::Entities::UserSafe
end

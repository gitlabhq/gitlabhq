class EventEntity < Grape::Entity
  expose :author, using: UserEntity
  expose :updated_at
end

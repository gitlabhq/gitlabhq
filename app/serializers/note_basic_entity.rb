class NoteBasicEntity < Grape::Entity
  expose :id
  expose :author, using: API::Entities::UserBasic
  expose :created_at
end

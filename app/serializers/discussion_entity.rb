class DiscussionEntity < Grape::Entity
  include RequestAwareEntity

  expose :id, :reply_id
  expose :expanded?, as: :expanded
  expose :author, using: UserEntity

  expose :created_at

  expose :last_updated_at, if: -> (discussion, _) { discussion.updated? }
  expose :last_updated_by, if: -> (discussion, _) { discussion.updated? }, using: UserEntity

  expose :notes, using: NoteEntity

  expose :individual_note?, as: :individual_note

  expose :can_reply do |discussion|
    can?(request.current_user, :create_note, discussion.project)
  end
end

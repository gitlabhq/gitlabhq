class DiscussionEntity < Grape::Entity
  include RequestAwareEntity

  expose :id, :reply_id
  expose :expanded?, as: :expanded

  expose :notes, using: NoteEntity

  expose :individual_note?, as: :individual_note
end

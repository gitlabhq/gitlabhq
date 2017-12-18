class DiscussionEntity < Grape::Entity
  include RequestAwareEntity

  expose :id, :reply_id
  expose :expanded?, as: :expanded

  expose :notes, using: NoteEntity

  expose :individual_note?, as: :individual_note
  expose :resolvable?, as: :resolvable
  expose :resolved?, as: :resolved
  expose :resolve_path, if: -> (d, _) { d.resolvable? } do |discussion|
    resolve_project_merge_request_discussion_path(discussion.project, discussion.noteable, discussion.id)
  end
end

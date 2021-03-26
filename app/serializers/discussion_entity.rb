# frozen_string_literal: true

class DiscussionEntity < BaseDiscussionEntity
  expose :notes do |discussion, opts|
    request.note_entity.represent(
      discussion.notes,
      opts.merge(
        with_base_discussion: false,
        discussion: discussion
      )
    )
  end

  expose :positions, if: -> (d, _) { display_merge_ref_discussions?(d) } do |discussion|
    discussion.diff_note_positions.map(&:position)
  end

  expose :line_codes, if: -> (d, _) { display_merge_ref_discussions?(d) } do |discussion|
    discussion.diff_note_positions.map(&:line_code)
  end

  expose :resolved?, as: :resolved
  expose :resolved_by_push?, as: :resolved_by_push
  expose :resolved_by, using: NoteUserEntity
  expose :resolved_at

  private

  def current_user
    request.current_user
  end

  def display_merge_ref_discussions?(discussion)
    discussion.diff_discussion? && !discussion.legacy_diff_discussion?
  end
end

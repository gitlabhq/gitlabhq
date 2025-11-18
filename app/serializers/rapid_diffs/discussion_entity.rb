# frozen_string_literal: true

module RapidDiffs
  class DiscussionEntity < Grape::Entity
    include RequestAwareEntity

    expose :id
    expose :reply_id
    expose :confidential?, as: :confidential
    expose :diff_discussion?, as: :diff_discussion

    expose :position, if: ->(d, _) { d.diff_discussion? && !d.legacy_diff_discussion? }

    expose :notes do |discussion, opts|
      RapidDiffs::NoteEntity.represent(
        discussion.notes,
        opts.merge(
          with_base_discussion: false,
          discussion: discussion
        )
      )
    end
  end
end

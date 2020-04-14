# frozen_string_literal: true

class DiffNotePosition < ApplicationRecord
  belongs_to :note

  enum diff_content_type: {
    text: 0,
    image: 1
  }

  enum diff_type: {
    head: 0
  }

  def position
    Gitlab::Diff::Position.new(
      old_path: old_path,
      new_path: new_path,
      old_line: old_line,
      new_line: new_line,
      position_type: diff_content_type,
      diff_refs: Gitlab::Diff::DiffRefs.new(
        base_sha: base_sha,
        start_sha: start_sha,
        head_sha: head_sha
      )
    )
  end

  def position=(position)
    position_attrs = position.to_h
    position_attrs[:diff_content_type] = position_attrs.delete(:position_type)

    assign_attributes(position_attrs)
  end
end

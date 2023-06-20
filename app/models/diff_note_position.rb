# frozen_string_literal: true

class DiffNotePosition < ApplicationRecord
  belongs_to :note
  attr_accessor :line_range

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
    assign_attributes(self.class.position_to_attrs(position))
  end

  def self.create_or_update_for(note, params)
    attrs = position_to_attrs(params[:position])
    attrs.merge!(params.slice(:diff_type, :line_code))
    attrs[:note_id] = note.id

    upsert(attrs, unique_by: [:note_id, :diff_type])
  end

  def self.position_to_attrs(position)
    position_attrs = position.to_h
    position_attrs[:diff_content_type] = position_attrs.delete(:position_type)
    position_attrs.except(:line_range, :ignore_whitespace_change)
  end
end

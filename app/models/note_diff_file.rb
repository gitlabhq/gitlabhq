# frozen_string_literal: true

class NoteDiffFile < ApplicationRecord
  include DiffFile
  include Gitlab::EncodingHelper

  scope :referencing_sha, ->(oids, project_id:) do
    joins(:diff_note).where(notes: { project_id: project_id, commit_id: oids })
  end

  delegate :original_position, :project, :resolved_at, to: :diff_note

  belongs_to :diff_note, inverse_of: :note_diff_file

  validates :diff_note, presence: true

  def raw_diff_file
    raw_diff = Gitlab::Git::Diff.new(to_hash)

    Gitlab::Diff::File.new(
      raw_diff,
      repository: project.repository,
      diff_refs: original_position.diff_refs,
      unique_identifier: id
    )
  end

  def diff_export
    force_encode_utf8(diff)
  rescue ArgumentError
    diff
  end
end

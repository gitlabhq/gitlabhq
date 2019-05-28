# frozen_string_literal: true

class NoteDiffFile < ApplicationRecord
  include DiffFile

  scope :for_commit_or_unresolved, -> do
    joins(:diff_note).where("resolved_at IS NULL OR noteable_type = 'Commit'")
  end

  scope :referencing_sha, -> (oids, project_id:) do
    joins(:diff_note).where(notes: { project_id: project_id, commit_id: oids })
  end

  delegate :original_position, :project, to: :diff_note

  belongs_to :diff_note, inverse_of: :note_diff_file

  validates :diff_note, presence: true

  def raw_diff_file
    raw_diff = Gitlab::Git::Diff.new(to_hash)

    Gitlab::Diff::File.new(raw_diff,
                           repository: project.repository,
                           diff_refs: original_position.diff_refs,
                           unique_identifier: id)
  end
end

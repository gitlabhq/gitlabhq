# frozen_string_literal: true

class NoteSummary
  attr_reader :note
  attr_reader :metadata

  def initialize(noteable, project, author, body, action: nil, commit_count: nil)
    @note = { noteable: noteable, project: project, author: author, note: body }
    @metadata = { action: action, commit_count: commit_count }.compact

    set_commit_params if note[:noteable].is_a?(Commit)
  end

  def metadata?
    metadata.present?
  end

  def set_commit_params
    note.merge!(noteable_type: 'Commit', commit_id: note[:noteable].id)
    note[:noteable] = nil
  end
end

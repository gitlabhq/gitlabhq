class CommitLoadContext < BaseContext
  def execute
    result = {
      commit: nil,
      suppress_diff: false,
      line_notes: [],
      notes_count: 0,
      note: nil,
      status: :ok
    }

    commit = project.repository.commit(params[:id])

    if commit
      line_notes = project.notes.for_commit_id(commit.id).inline

      result[:commit] = commit
      result[:note] = project.build_commit_note(commit)
      result[:line_notes] = line_notes
      result[:notes_count] = project.notes.for_commit_id(commit.id).count
      result[:branches] = project.repository.branch_names_contains(commit.id)

      begin
        result[:suppress_diff] = true if commit.diff_suppress? && !params[:force_show_diff]
        result[:force_suppress_diff] = commit.diff_force_suppress?
      rescue Grit::Git::GitTimeout
        result[:suppress_diff] = true
        result[:status] = :huge_commit
      end
    end

    result
  end
end

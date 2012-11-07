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

    commit = project.commit(params[:id])

    if commit
      commit = CommitDecorator.decorate(commit)
      line_notes = project.commit_line_notes(commit)

      result[:commit] = commit
      result[:note] = project.build_commit_note(commit)
      result[:line_notes] = line_notes
      result[:notes_count] = line_notes.count + project.commit_notes(commit).count

      begin
        result[:suppress_diff] = true if commit.diffs.size > 200 && !params[:force_show_diff]
      rescue Grit::Git::GitTimeout
        result[:suppress_diff] = true
        result[:status] = :huge_commit
      end
    end

    result
  end
end

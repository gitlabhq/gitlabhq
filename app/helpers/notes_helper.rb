module NotesHelper
  include DiscussionHelper

  def loading_more_notes?
    params[:loading_more].present?
  end

  def loading_new_notes?
    params[:loading_new].present?
  end

   # Helps to distinguish e.g. commit notes in mr notes list
  def note_for_main_target?(note)
    !@mixed_targets || @main_target_type == note.noteable_type
  end

  def link_to_commit_diff_line_note(note)
    commit = note.noteable
    diff_index, diff_old_line, diff_new_line = note.line_code.split('_')

    link_file = commit.diffs[diff_index.to_i].new_path
    link_line = diff_new_line

    link_to "#{link_file}:L#{link_line}", project_commit_path(@project, commit, anchor: note.line_code)
  end

  def link_to_merge_request_diff_line_note(note)
    return unless note.line_note?

    mr = note.target
    diff_index, diff_old_line, diff_new_line = note.line_code.split('_')

    link_file = mr.diffs[diff_index.to_i].b_path
    link_line = diff_new_line

    link_to "#{link_file}:L#{link_line}", diffs_project_merge_request_path(note.project, note.noteable_id, anchor: note.line_code)
  end
end

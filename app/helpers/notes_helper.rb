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
    if note.for_diff_line?
      link_to "#{note.diff.new_path}:L#{note.diff_new_line}", project_commit_path(@project, note.noteable, anchor: note.noteable)
    end
  end

  def link_to_merge_request_diff_line_note(note)
    if note.for_diff_line?
      link_to "#{note.diff.b_path}:L#{note.diff_new_line}", diffs_project_merge_request_path(note.project, note.noteable_id, anchor: note.noteable)
    end
  end
end

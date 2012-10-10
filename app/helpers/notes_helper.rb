module NotesHelper
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

  end
end

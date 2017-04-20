module RendersNotes
  def prepare_notes_for_rendering(notes)
    preload_noteable_for_regular_notes(notes)
    preload_max_access_for_authors(notes, @project)
    Banzai::NoteRenderer.render(notes, @project, current_user)

    notes
  end

  private

  def preload_max_access_for_authors(notes, project)
    user_ids = notes.map(&:author_id)
    project.team.max_member_access_for_user_ids(user_ids)
  end

  def preload_noteable_for_regular_notes(notes)
    ActiveRecord::Associations::Preloader.new.preload(notes.reject(&:for_commit?), :noteable)
  end
end

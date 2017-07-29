module RendersNotes
  def prepare_notes_for_rendering(notes, noteable=nil)
    preload_noteable_for_regular_notes(notes)
    preload_max_access_for_authors(notes, @project)
    preload_first_time_contribution_for_authors(noteable, notes) if noteable.is_a?(Issuable)
    Banzai::NoteRenderer.render(notes, @project, current_user)

    notes
  end

  private

  def preload_max_access_for_authors(notes, project)
    return nil unless project

    user_ids = notes.map(&:author_id)
    project.team.max_member_access_for_user_ids(user_ids)
  end

  def preload_noteable_for_regular_notes(notes)
    ActiveRecord::Associations::Preloader.new.preload(notes.reject(&:for_commit?), :noteable)
  end

  def preload_first_time_contribution_for_authors(issuable, notes)
    return unless issuable.first_contribution?
    same_author = lambda {|n| n.author_id == issuable.author_id}
    notes.select(&same_author).each {|note| note.special_role = :first_time_contributor}
  end
end

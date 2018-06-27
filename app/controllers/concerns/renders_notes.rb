module RendersNotes
  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def prepare_notes_for_rendering(notes, noteable = nil)
    preload_noteable_for_regular_notes(notes)
    preload_max_access_for_authors(notes, @project)
    preload_first_time_contribution_for_authors(noteable, notes)
    Notes::RenderService.new(current_user).execute(notes)

    notes
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  private

  def preload_max_access_for_authors(notes, project)
    return nil unless project

    user_ids = notes.map(&:author_id)
    project.team.max_member_access_for_user_ids(user_ids)
  end

  def preload_noteable_for_regular_notes(notes)
    ActiveRecord::Associations::Preloader.new.preload(notes.reject(&:for_commit?), :noteable)
  end

  def preload_first_time_contribution_for_authors(noteable, notes)
    return unless noteable.is_a?(Issuable) && noteable.first_contribution?

    notes.each {|n| n.specialize_for_first_contribution!(noteable)}
  end
end

# frozen_string_literal: true

module RendersNotes
  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def prepare_notes_for_rendering(notes)
    preload_noteable_for_regular_notes(notes)
    preload_note_namespace(notes)
    preload_max_access_for_authors(notes, @project)
    preload_author_status(notes)
    Notes::RenderService.new(current_user).execute(notes)

    notes
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  # Calling prepare_notes_for_rendering before filtering is important:
  # without it, Note#system_note_visible_for? (via Note#readable_by?)
  # will attempt to render Markdown references mentioned in the note to
  # see whether they should be redacted. For notes that reference a
  # commit, this would also incur a Gitaly call to verify the commit
  # exists.
  #
  # With prepare_notes_for_rendering, we can avoid Gitaly calls because
  # notes are redacted if they point to projects that cannot be accessed
  # by the user.
  def prepare_and_filter_notes(notes)
    notes = prepare_notes_for_rendering(notes)
    notes.select { |note| note.readable_by?(current_user) }
  end

  private

  def preload_note_namespace(notes)
    ActiveRecord::Associations::Preloader.new(records: notes, associations: :namespace).call
  end

  def preload_max_access_for_authors(notes, project)
    return unless project

    user_ids = notes.map(&:author_id)
    access = project.team.max_member_access_for_user_ids(user_ids).select do |_k, v|
      v == Gitlab::Access::NO_ACCESS
    end.keys
    project.team.contribution_check_for_user_ids(access)
  end

  def preload_noteable_for_regular_notes(notes)
    ActiveRecord::Associations::Preloader.new(records: notes.reject(&:for_commit?), associations: :noteable).call
  end

  def preload_author_status(notes)
    ActiveRecord::Associations::Preloader.new(records: notes, associations: { author: :status }).call
  end
end

# frozen_string_literal: true

module RendersNotes
  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def prepare_notes_for_rendering(notes, noteable = nil)
    preload_noteable_for_regular_notes(notes)
    preload_max_access_for_authors(notes, @project)
    preload_author_status(notes)
    Notes::RenderService.new(current_user).execute(notes)

    notes
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  private

  def preload_max_access_for_authors(notes, project)
    return unless project

    user_ids = notes.map(&:author_id)
    access = project.team.max_member_access_for_user_ids(user_ids).select { |k, v| v == Gitlab::Access::NO_ACCESS }.keys
    project.team.contribution_check_for_user_ids(access)
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def preload_noteable_for_regular_notes(notes)
    ActiveRecord::Associations::Preloader.new.preload(notes.reject(&:for_commit?), :noteable)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # rubocop: disable CodeReuse/ActiveRecord
  def preload_author_status(notes)
    ActiveRecord::Associations::Preloader.new.preload(notes, { author: :status })
  end
  # rubocop: enable CodeReuse/ActiveRecord
end

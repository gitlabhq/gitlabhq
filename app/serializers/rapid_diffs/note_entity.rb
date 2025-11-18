# frozen_string_literal: true

module RapidDiffs
  class NoteEntity < ProjectNoteEntity
    include RequestAwareEntity

    expose :id do |note|
      note.id.to_s
    end

    expose :discussion_id

    expose :is_noteable_author do |note|
      note.noteable_author?(note.noteable)
    end

    unexpose :is_contributor
    expose :contributor?, as: :is_contributor

    # Remove fields not needed for rapid diffs
    unexpose :suggestions
    unexpose :resolved?
    unexpose :resolvable?
    unexpose :resolved_by
    unexpose :resolved_by_push?
    unexpose :system_note_icon_name
    unexpose :outdated_line_change_path
    unexpose :resolve_path
    unexpose :resolve_with_issue_path
    unexpose :cached_markdown_version
    unexpose :discussion, :base_discussion

    expose :current_user do
      expose :can_edit do |note|
        can?(current_user, :admin_note, note)
      end
      expose :can_award_emoji do |note|
        can?(current_user, :award_emoji, note)
      end
    end

    private

    def current_user
      request.current_user
    end

    def note_presenter(note)
      NotePresenter.new(note, current_user: current_user) # rubocop: disable CodeReuse/Presenter -- Directly instantiate NotePresenter because we don't have presenters for all subclasses of Note
    end
  end
end

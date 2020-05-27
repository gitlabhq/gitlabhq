# frozen_string_literal: true

module DraftNotes
  class CreateService < DraftNotes::BaseService
    attr_accessor :in_draft_mode, :in_reply_to_discussion_id

    def initialize(merge_request, current_user, params = nil)
      @in_reply_to_discussion_id = params.delete(:in_reply_to_discussion_id)
      super
    end

    def execute
      if in_reply_to_discussion_id.present?
        unless discussion
          return base_error(_('Thread to reply to cannot be found'))
        end

        params[:discussion_id] = discussion.reply_id
      end

      if params[:resolve_discussion] && !can_resolve_discussion?
        return base_error(_('User is not allowed to resolve thread'))
      end

      draft_note = DraftNote.new(params)
      draft_note.merge_request = merge_request
      draft_note.author = current_user
      draft_note.save

      if in_reply_to_discussion_id.blank? && draft_note.diff_file&.unfolded?
        merge_request.diffs.clear_cache
      end

      draft_note
    end

    private

    def base_error(text)
      DraftNote.new.tap do |draft|
        draft.errors.add(:base, text)
      end
    end

    def discussion
      @discussion ||= merge_request.notes.find_discussion(in_reply_to_discussion_id)
    end

    def can_resolve_discussion?
      note = discussion&.notes&.first
      return false unless note

      current_user && Ability.allowed?(current_user, :resolve_note, note)
    end
  end
end

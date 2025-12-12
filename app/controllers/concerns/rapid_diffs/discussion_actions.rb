# frozen_string_literal: true

module RapidDiffs
  module DiscussionActions
    # rubocop:disable Gitlab/ModuleWithInstanceVariables -- Need @project as is
    def create_discussions_for_resource
      return render_404 unless rapid_diffs_enabled?
      return access_denied! unless can?(current_user, :create_note, noteable)
      return unless valid_discussion_params?

      note = Notes::CreateService.new(@project, current_user, create_note_params).execute

      if note.errors.present?
        render json: { errors: note.errors.full_messages.to_sentence }, status: :unprocessable_entity
        return
      end

      discussion = note.discussion
      prepare_notes_for_rendering(discussion.notes)

      serialized_discussion = RapidDiffs::DiscussionSerializer.new(
        project: @project,
        noteable: noteable,
        current_user: current_user,
        note_entity: RapidDiffs::NoteEntity
      ).represent(discussion)

      render json: { discussion: serialized_discussion }
    end
    # rubocop:enable Gitlab/ModuleWithInstanceVariables

    private

    def rapid_diffs_enabled?
      raise NotImplementedError, "#{self.class} must implement #rapid_diffs_enabled?"
    end

    def noteable
      raise NotImplementedError, "#{self.class} must implement #noteable"
    end

    def create_note_params
      raise NotImplementedError, "#{self.class} must implement #create_note_params"
    end

    def valid_discussion_params?
      if create_note_params[:in_reply_to_discussion_id].present?
        validate_reply_target!
      else
        true
      end
    end

    def validate_reply_target!
      discussion_id = create_note_params[:in_reply_to_discussion_id]
      all_discussions = grouped_discussions.values.flatten + timeline_discussions
      target_discussion = all_discussions.find { |d| d.id == discussion_id }

      unless target_discussion
        render json: { errors: "Discussion not found" }, status: :unprocessable_entity
        return false
      end

      true
    end
  end
end

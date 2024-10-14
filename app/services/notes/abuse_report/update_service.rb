# frozen_string_literal: true

module Notes
  module AbuseReport
    class UpdateService < ::BaseService
      def initialize(user = nil, params = {})
        @current_user = user
        @params = params
      end

      def execute(note)
        raise Gitlab::Access::AccessDeniedError unless can?(current_user, :update_note, note)

        note.assign_attributes(params)

        return error([_('The provided params did not update the note.')]) unless note.note_changed?
        return error(note.errors.full_messages) unless note.valid?

        update_note(note)

        ServiceResponse.success
      end

      private

      def update_note(note)
        note.assign_attributes(last_edited_at: Time.current, updated_by: current_user)
        note.save
      end

      def error(message)
        ServiceResponse.error(message: message)
      end
    end
  end
end

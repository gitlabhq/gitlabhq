module Emails
  module EE
    module Notes
      extend ::Gitlab::Utils::Override

      def note_epic_email(recipient_id, note_id)
        setup_note_mail(note_id, recipient_id)

        @epic = @note.noteable
        @target_url = group_epic_url(*note_target_url_options)
        mail_answer_note_thread(@epic, @note, note_thread_options(recipient_id))
      end
    end
  end
end

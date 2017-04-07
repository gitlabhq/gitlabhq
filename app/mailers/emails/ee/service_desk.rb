module Emails
  module EE
    module ServiceDesk
      extend ActiveSupport::Concern

      included do
        layout 'service_desk', only: [:service_desk_thank_you_email, :service_desk_new_note_email]
      end

      def service_desk_thank_you_email(issue_id)
        setup_service_desk_mail(issue_id)

        mail_new_thread(@issue, service_desk_options(@support_bot.id))
      end

      def service_desk_new_note_email(issue_id, note_id)
        @note = Note.find(note_id)
        setup_service_desk_mail(issue_id)
        mail_answer_thread(@issue, service_desk_options(@note.author_id))
      end

      private

      def setup_service_desk_mail(issue_id)
        @issue = Issue.find(issue_id)
        @project = @issue.project
        @support_bot = User.support_bot

        @sent_notification = SentNotification.record(@issue, @support_bot.id, reply_key)
      end

      def service_desk_options(author_id)
        {
          from: sender(author_id),
          to: @issue.service_desk_reply_to,
          subject: "Re: #{@issue.title} (##{@issue.iid})"
        }
      end
    end
  end
end

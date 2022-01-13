# frozen_string_literal: true

module Gitlab
  module Email
    module FailureHandler
      def self.handle(receiver, error)
        can_retry = false
        reason =
          case error
          when Gitlab::Email::UnknownIncomingEmail
            s_("EmailError|We couldn't figure out what the email is for. Please create your issue or comment through the web interface.")
          when Gitlab::Email::SentNotificationNotFoundError
            s_("EmailError|We couldn't figure out what the email is in reply to. Please create your comment through the web interface.")
          when Gitlab::Email::ProjectNotFound
            s_("EmailError|We couldn't find the project. Please check if there's any typo.")
          when Gitlab::Email::EmptyEmailError
            can_retry = true
            s_("EmailError|It appears that the email is blank. Make sure your reply is at the top of the email, we can't process inline replies.")
          when Gitlab::Email::UserNotFoundError
            s_("EmailError|We couldn't figure out what user corresponds to the email. Please create your comment through the web interface.")
          when Gitlab::Email::UserBlockedError
            s_("EmailError|Your account has been blocked. If you believe this is in error, contact a staff member.")
          when Gitlab::Email::UserNotAuthorizedError
            s_("EmailError|You are not allowed to perform this action. If you believe this is in error, contact a staff member.")
          when Gitlab::Email::NoteableNotFoundError
            s_("EmailError|The thread you are replying to no longer exists, perhaps it was deleted? If you believe this is in error, contact a staff member.")
          when Gitlab::Email::InvalidAttachment
            error.message
          when Gitlab::Email::InvalidRecordError
            can_retry = true
            error.message
          when Gitlab::Email::EmailTooLarge
            s_("EmailError|We couldn't process your email because it is too large. Please create your issue or comment through the web interface.")
          end

        if reason
          receiver.mail.body = nil

          EmailRejectionMailer.rejection(reason, receiver.mail.encoded, can_retry).deliver_later
        end

        reason
      end
    end
  end
end

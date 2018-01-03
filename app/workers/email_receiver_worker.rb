class EmailReceiverWorker
  include ApplicationWorker

  def perform(raw)
    return unless Gitlab::IncomingEmail.enabled?

    begin
      Gitlab::Email::Receiver.new(raw).execute
    rescue => e
      handle_failure(raw, e)
    end
  end

  private

  def handle_failure(raw, e)
    Rails.logger.warn("Email can not be processed: #{e}\n\n#{raw}")

    return unless raw.present?

    can_retry = false
    reason =
      case e
      when Gitlab::Email::UnknownIncomingEmail
        "We couldn't figure out what the email is for. Please create your issue or comment through the web interface."
      when Gitlab::Email::SentNotificationNotFoundError
        "We couldn't figure out what the email is in reply to. Please create your comment through the web interface."
      when Gitlab::Email::ProjectNotFound
        "We couldn't find the project. Please check if there's any typo."
      when Gitlab::Email::EmptyEmailError
        can_retry = true
        "It appears that the email is blank. Make sure your reply is at the top of the email, we can't process inline replies."
      when Gitlab::Email::UserNotFoundError
        "We couldn't figure out what user corresponds to the email. Please create your comment through the web interface."
      when Gitlab::Email::UserBlockedError
        "Your account has been blocked. If you believe this is in error, contact a staff member."
      when Gitlab::Email::UserNotAuthorizedError
        "You are not allowed to perform this action. If you believe this is in error, contact a staff member."
      when Gitlab::Email::NoteableNotFoundError
        "The thread you are replying to no longer exists, perhaps it was deleted? If you believe this is in error, contact a staff member."
      when Gitlab::Email::InvalidRecordError
        can_retry = true
        e.message
      end

    if reason
      EmailRejectionMailer.rejection(reason, raw, can_retry).deliver_later
    end
  end
end

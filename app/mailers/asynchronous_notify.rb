require 'celluloid'

class AsynchronousNotify < ActionMailer::Base
  include Celluloid

  def self.broadcast_message_email(sender, recipients, broadcast_message_id)
    job = AsynchronousNotify.new
    job.load(sender, recipients, broadcast_message_id)
    job.async.run
  end

  # Work task to be run asynchronously
  def run
    from = Mail::Address.new(Gitlab.config.gitlab.email_from)
    reply_to = "noreply@#{Gitlab.config.gitlab.host}"
    subject = "Broadcast message from Gitlab #{Time.now}"
    broadcast_message = BroadcastMessage.find(@broadcast_message_id).message

    @recipients.each do |recipient|
      mail = mail(
        from: from,
        to: recipient.email,
        reply_to: reply_to,
        subject: subject,
        body: broadcast_message
      )
      mail.deliver
    end
  end

  def load(sender, recipients, broadcast_message_id)
    @sender = sender
    @recipients = recipients
    @broadcast_message_id = broadcast_message_id
  end
end

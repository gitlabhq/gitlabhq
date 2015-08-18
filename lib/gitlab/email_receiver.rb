module Gitlab
  class EmailReceiver
    def initialize(raw)
      @raw = raw
    end

    def message
      @message ||= Mail::Message.new(@raw)
    end

    def process
      return unless message && sent_notification

      Notes::CreateService.new(
        sent_notification.project,
        sent_notification.recipient,
        note:           message.text_part.to_s,
        noteable_type:  sent_notification.noteable_type,
        noteable_id:    sent_notification.noteable_id,
        commit_id:      sent_notification.commit_id
      ).execute
    end

    private

    def reply_key
      address = Gitlab.config.reply_by_email.address
      return nil unless address

      regex = Regexp.escape(address)
      regex = regex.gsub(Regexp.escape('%{reply_key}'), "(.*)")
      regex = Regexp.new(regex)

      address = message.to.find { |address| address =~ regex }
      return nil unless address

      match = address.match(regex)
        
      return nil unless match && match[1].present?

      match[1]
    end

    def sent_notification
      return nil unless reply_key
      
      SentNotification.for(reply_key)
    end
  end
end

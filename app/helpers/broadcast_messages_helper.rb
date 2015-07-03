module BroadcastMessagesHelper
  def broadcast_styling(broadcast_message)
    styling = ''

    if broadcast_message.color.present?
      styling << "background-color: #{broadcast_message.color}"
      styling << '; ' if broadcast_message.font.present?
    end

    if broadcast_message.font.present?
      styling << "color: #{broadcast_message.font}"
    end

    styling
  end
end

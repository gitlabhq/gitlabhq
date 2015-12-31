module BroadcastMessagesHelper
  def broadcast_message(message = BroadcastMessage.current)
    return unless message.present?

    content_tag :div, class: 'broadcast-message', style: broadcast_message_style(message) do
      icon('bullhorn') << ' ' << message.message
    end
  end

  def broadcast_message_style(broadcast_message)
    style = ''

    if broadcast_message.color.present?
      style << "background-color: #{broadcast_message.color}"
      style << '; ' if broadcast_message.font.present?
    end

    if broadcast_message.font.present?
      style << "color: #{broadcast_message.font}"
    end

    style
  end
end

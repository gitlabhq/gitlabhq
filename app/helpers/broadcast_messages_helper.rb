module BroadcastMessagesHelper
  def broadcast_message(message = BroadcastMessage.current)
    return unless message.present?

    content_tag :div, class: 'broadcast-message', style: broadcast_message_style(message) do
      icon('bullhorn') << ' ' << render_broadcast_message(message.message)
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

  def broadcast_message_status(broadcast_message)
    if broadcast_message.active?
      'Active'
    elsif broadcast_message.ended?
      'Expired'
    else
      'Pending'
    end
  end

  def render_broadcast_message(message)
    Banzai.render(message, pipeline: :broadcast_message).html_safe
  end
end

# frozen_string_literal: true

module BroadcastMessagesHelper
  def current_broadcast_messages
    BroadcastMessage.current(request.path)
  end

  def broadcast_message(message)
    return unless message.present?

    content_tag :div, dir: 'auto', class: 'broadcast-message', style: broadcast_message_style(message) do
      sprite_icon('bullhorn', size: 16, css_class: 'vertical-align-text-top mr-2') << ' ' << render_broadcast_message(message)
    end
  end

  def broadcast_message_style(broadcast_message)
    style = []

    if broadcast_message.color.present?
      style << "background-color: #{broadcast_message.color}"
    end

    if broadcast_message.font.present?
      style << "color: #{broadcast_message.font}"
    end

    style.join('; ')
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

  def render_broadcast_message(broadcast_message)
    Banzai.render_field(broadcast_message, :message).html_safe
  end
end

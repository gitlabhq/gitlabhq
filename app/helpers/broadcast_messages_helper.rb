# frozen_string_literal: true

module BroadcastMessagesHelper
  def current_broadcast_banner_messages
    BroadcastMessage.current_banner_messages(request.path)
  end

  def current_broadcast_notification_message
    BroadcastMessage.current_notification_messages(request.path).last
  end

  def broadcast_message(message, opts = {})
    return unless message.present?

    classes = "broadcast-#{message.broadcast_type}-message #{opts[:preview] && 'preview'}"

    content_tag :div, dir: 'auto', class: classes, style: broadcast_message_style(message) do
      concat sprite_icon('bullhorn', size: 16, css_class: 'vertical-align-text-top')
      concat ' '
      concat render_broadcast_message(message)
    end
  end

  def broadcast_message_style(broadcast_message)
    return '' if broadcast_message.notification?

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

  def broadcast_type_options
    BroadcastMessage.broadcast_types.keys.map { |w| [w.humanize, w] }
  end
end

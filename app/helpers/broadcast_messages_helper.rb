# frozen_string_literal: true

module BroadcastMessagesHelper
  def current_broadcast_banner_messages
    BroadcastMessage.current_banner_messages(request.path).select do |message|
      cookies["hide_broadcast_message_#{message.id}"].blank?
    end
  end

  def current_broadcast_notification_message
    not_hidden_messages = BroadcastMessage.current_notification_messages(request.path).select do |message|
      cookies["hide_broadcast_message_#{message.id}"].blank?
    end
    not_hidden_messages.last
  end

  def broadcast_message(message, opts = {})
    return unless message.present?

    render "shared/broadcast_message", { message: message, opts: opts }
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
    if broadcast_message.notification?
      Banzai.render_field_and_post_process(broadcast_message, :message, {
        current_user: current_user,
        skip_project_check: true,
        broadcast_message_placeholders: true
      }).html_safe
    else
      Banzai.render_field(broadcast_message, :message).html_safe
    end
  end

  def broadcast_type_options
    BroadcastMessage.broadcast_types.keys.map { |w| [w.humanize, w] }
  end
end

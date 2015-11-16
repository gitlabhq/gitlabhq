module NotificationsHelper
  include IconsHelper

  def notification_icon(notification)
    if notification.disabled?
      icon('volume-off', class: 'ns-mute')
    elsif notification.participating?
      icon('volume-down', class: 'ns-part')
    elsif notification.watch?
      icon('volume-up', class: 'ns-watch')
    else
      icon('circle-o', class: 'ns-default')
    end
  end

  def notification_list_item(notification_level, user_membership)
    case notification_level
    when Notification::N_DISABLED
      update_notification_link(Notification::N_DISABLED, user_membership, 'Disabled', 'microphone-slash')
    when Notification::N_PARTICIPATING
      update_notification_link(Notification::N_PARTICIPATING, user_membership, 'Participate', 'volume-up')
    when Notification::N_WATCH
      update_notification_link(Notification::N_WATCH, user_membership, 'Watch', 'eye')
    when Notification::N_MENTION
      update_notification_link(Notification::N_MENTION, user_membership, 'On mention', 'at')
    when Notification::N_GLOBAL
      update_notification_link(Notification::N_GLOBAL, user_membership, 'Global', 'globe')
    else
      # do nothing
    end
  end

  def update_notification_link(notification_level, user_membership, title, icon)
    content_tag(:li, class: active_level_for(user_membership, notification_level)) do
      link_to '#', class: 'update-notification', data: { notification_level: notification_level } do
        icon("#{icon} fw", text: title)
      end
    end
  end

  def notification_label(user_membership)
    Notification.new(user_membership).to_s
  end

  def active_level_for(user_membership, level)
    'active' if user_membership.notification_level == level
  end
end

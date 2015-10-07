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
      content_tag(:li, class: active_level_for(user_membership, Notification::N_DISABLED)) do
        link_to '#', class: 'update-notification', data: { notification_level: Notification::N_DISABLED } do
          icon('microphone-slash fw', text: 'Disabled')
        end
      end
    when Notification::N_PARTICIPATING
      content_tag(:li, class: active_level_for(user_membership, Notification::N_PARTICIPATING)) do
        link_to '#', class: 'update-notification', data: { notification_level: Notification::N_PARTICIPATING } do
          icon('volume-up fw', text: 'Participate')
        end
      end
    when Notification::N_WATCH
      content_tag(:li, class: active_level_for(user_membership, Notification::N_WATCH)) do
        link_to '#', class: 'update-notification', data: { notification_level: Notification::N_WATCH } do
          icon('eye fw', text: 'Watch')
        end
      end
    when Notification::N_MENTION
      content_tag(:li, class: active_level_for(user_membership, Notification::N_MENTION)) do
        link_to '#', class: 'update-notification', data: { notification_level: Notification::N_MENTION }  do
          icon('at fw', text: 'On mention')
        end
      end
    when Notification::N_GLOBAL
      content_tag(:li, class: active_level_for(user_membership, Notification::N_GLOBAL)) do
        link_to '#', class: 'update-notification', data: { notification_level: Notification::N_GLOBAL } do
          icon('globe fw', text: 'Global')
        end
      end
    else
      # do nothing
    end
  end

  def notification_label(user_membership)
    Notification.new(user_membership).to_s
  end

  def active_level_for(user_membership, level)
    'active' if user_membership.notification_level == level
  end
end

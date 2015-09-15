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

  def notification_list_item(notification_level)
    case notification_level
    when Notification::N_DISABLED
      content_tag(:li) do
        link_to '#', class: 'update-notification', data: { notification_level: Notification::N_DISABLED } do
          icon('microphone-slash fw', text: 'Disabled')
        end
      end
    when Notification::N_PARTICIPATING
      content_tag(:li) do
        link_to '#', class: 'update-notification', data: { notification_level: Notification::N_PARTICIPATING } do
          icon('volume-up fw', text: 'Participating')
        end
      end
    when Notification::N_WATCH
      content_tag(:li) do
        link_to '#', class: 'update-notification', data: { notification_level: Notification::N_WATCH } do
          icon('globe fw', text: 'Watch')
        end
      end
    when Notification::N_MENTION
      content_tag(:li) do
        link_to '#', class: 'update-notification', data: { notification_level: Notification::N_MENTION }  do
          icon('at fw', text: 'Mention')
        end
      end
    else
      # do nothing
    end
  end
end

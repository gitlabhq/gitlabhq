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
          icon('microphone-slash')
          'Disabled'
        end
      when Notification::N_PARTICIPATING
        content_tag(:li) do
          icon('volume-up')
          'Participating'
        end
      when Notification::N_WATCH
        content_tag(:li) do
          icon('globe')
          'Watch'
        end
      when Notification::N_MENTION
        content_tag(:li) do
          icon('at')
          'Mention'
        end
      else
        # do nothing
    end
  end
end

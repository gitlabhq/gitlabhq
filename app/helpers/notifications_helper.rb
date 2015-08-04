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
end

module NotificationsHelper
  def notification_icon(notification)
    if notification.disabled?
      content_tag :i, nil, class: 'icon-volume-off ns-mute'
    elsif notification.participating?
      content_tag :i, nil, class: 'icon-volume-down ns-part'
    elsif notification.watch?
      content_tag :i, nil, class: 'icon-volume-up ns-watch'
    else
      content_tag :i, nil, class: 'icon-circle-blank ns-default'
    end
  end
end

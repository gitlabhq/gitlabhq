module NotificationsHelper
  def notification_icon(notification)
    if notification.disabled?
      content_tag :i, nil, class: 'fa fa-volume-off ns-mute'
    elsif notification.participating?
      content_tag :i, nil, class: 'fa fa-volume-down ns-part'
    elsif notification.watch?
      content_tag :i, nil, class: 'fa fa-volume-up ns-watch'
    else
      content_tag :i, nil, class: 'fa fa-circle-o ns-default'
    end
  end
end

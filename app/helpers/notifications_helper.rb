module NotificationsHelper
  def notification_icon(notification)
    if notification.disabled?
      content_tag :i, nil, class: 'icon-circle cred'
    elsif notification.participating?
      content_tag :i, nil, class: 'icon-circle cblue'
    elsif notification.watch?
      content_tag :i, nil, class: 'icon-circle cgreen'
    else
      content_tag :i, nil, class: 'icon-circle-blank cblue'
    end
  end
end

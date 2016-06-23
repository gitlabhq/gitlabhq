((w) ->
  notificationGranted = (message, opts, onclick) ->
    notification = new Notification(message, opts)

    # Hide the notification after X amount of seconds
    setTimeout ->
      notification.close()
    , 8000

    if onclick
      notification.onclick = onclick

  notifyPermissions = ->
    if 'Notification' of window
      Notification.requestPermission()

  notifyMe = (message, body, icon, onclick) ->
    opts =
      body: body
      icon: icon
    # Let's check if the browser supports notifications
    if !('Notification' of window)
      # do nothing
    else if Notification.permission == 'granted'
      # If it's okay let's create a notification
      notificationGranted message, opts, onclick
    else if Notification.permission != 'denied'
      Notification.requestPermission (permission) ->
        # If the user accepts, let's create a notification
        if permission == 'granted'
          notificationGranted message, opts, onclick

  w.notify = notifyMe
  w.notifyPermissions = notifyPermissions
) window

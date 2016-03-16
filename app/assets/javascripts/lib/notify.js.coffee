((w) ->
  notifyPermissions = ->
    if 'Notification' of window
      Notification.requestPermission()

  notifyMe = (message, body, icon, onclick) ->
    notification = undefined
    opts =
      body: body
      icon: icon
    # Let's check if the browser supports notifications
    if !('Notification' of window)
      # do nothing
    else if Notification.permission == 'granted'
      # If it's okay let's create a notification
      notification = new Notification(message, opts)

      if onclick
        notification.onclick = onclick
    else if Notification.permission != 'denied'
      Notification.requestPermission (permission) ->
        # If the user accepts, let's create a notification
        if permission == 'granted'
          notification = new Notification(message, opts)

          if onclick
            notification.onclick = onclick
        return
    return

  w.notify = notifyMe
  w.notifyPermissions = notifyPermissions
  return
) window

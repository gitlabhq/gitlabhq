# Written by GitLab @gitlab

((w) ->
  notifyMe = (message,body, icon) ->
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
    else if Notification.permission != 'denied'
      Notification.requestPermission (permission) ->
        # If the user accepts, let's create a notification
        if permission == 'granted'
          notification = new Notification(message, opts)
        return
    return

  w.notify = notifyMe
  return
) window

Notification.requestPermission()
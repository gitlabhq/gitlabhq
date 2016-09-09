(function() {
  (function(w) {
    var notificationGranted, notifyMe, notifyPermissions;
    notificationGranted = function(message, opts, onclick) {
      var notification;
      notification = new Notification(message, opts);
      setTimeout(function() {
        return notification.close();
      // Hide the notification after X amount of seconds
      }, 8000);
      if (onclick) {
        return notification.onclick = onclick;
      }
    };
    notifyPermissions = function() {
      if ('Notification' in window) {
        return Notification.requestPermission();
      }
    };
    notifyMe = function(message, body, icon, onclick) {
      var opts;
      opts = {
        body: body,
        icon: icon
      };
      // Let's check if the browser supports notifications
      if (!('Notification' in window)) {

      // do nothing
      } else if (Notification.permission === 'granted') {
        // If it's okay let's create a notification
        return notificationGranted(message, opts, onclick);
      } else if (Notification.permission !== 'denied') {
        return Notification.requestPermission(function(permission) {
          // If the user accepts, let's create a notification
          if (permission === 'granted') {
            return notificationGranted(message, opts, onclick);
          }
        });
      }
    };
    w.notify = notifyMe;
    return w.notifyPermissions = notifyPermissions;
  })(window);

}).call(this);

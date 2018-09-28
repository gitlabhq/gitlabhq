/* eslint-disable func-names, no-var, consistent-return, prefer-arrow-callback, no-return-assign, object-shorthand, comma-dangle, max-len */

function notificationGranted(message, opts, onclick) {
  var notification;
  notification = new Notification(message, opts);
  setTimeout(function() {
    // Hide the notification after X amount of seconds
    return notification.close();
  }, 8000);

  return notification.onclick = onclick || notification.close;
}

function notifyPermissions() {
  if ('Notification' in window) {
    return Notification.requestPermission();
  }
}

function notifyMe(message, body, icon, onclick) {
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
}

const notify = {
  notificationGranted,
  notifyPermissions,
  notifyMe,
};

export default notify;

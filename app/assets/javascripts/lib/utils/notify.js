/* eslint-disable consistent-return, no-return-assign */

function notificationGranted(message, opts, onclick) {
  const notification = new Notification(message, opts);
  setTimeout(
    () =>
      // Hide the notification after X amount of seconds
      notification.close(),
    8000,
  );

  return (notification.onclick = onclick || notification.close);
}

function notifyPermissions() {
  /* eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings */
  if ('Notification' in window) {
    return Notification.requestPermission();
  }
}

function notifyMe(message, body, icon, onclick) {
  const opts = {
    body,
    icon,
  };
  // Let's check if the browser supports notifications
  /* eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings */
  if (!('Notification' in window)) {
    // do nothing
  } else if (Notification.permission === 'granted') {
    // If it's okay let's create a notification
    return notificationGranted(message, opts, onclick);
  } else if (Notification.permission !== 'denied') {
    return Notification.requestPermission(permission => {
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

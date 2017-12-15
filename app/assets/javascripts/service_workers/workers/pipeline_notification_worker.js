function onPush(event) {
  console.log('PipelineNotificatinWorker onPush', event);

  const title = (event.data && event.data.text()) || 'Yay a message';

  event.waitUntil(
    self.registration.showNotification(title, {
      body: 'We have received a push message',
      icon: '/assets/path/to/icon.png',
      tag: 'push-simple-demo-notification-tag',
    }),
  );
}

self.addEventListener('install', () => {
  console.log('PipelineNotificationWorker install');
});

self.addEventListener('push', onPush);

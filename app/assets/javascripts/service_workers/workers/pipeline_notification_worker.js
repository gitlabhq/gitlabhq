function onPush(event) {
  console.log('PipelineNotificatinWorker onPush', event);
  debugger;
  console.log('JSON', event.data.json());
  console.log('logo', gon);
  console.log('test');

  const title = (event.data && event.data.text()) || 'Yay a message';

  event.waitUntil(
    self.registration.showNotification(title, {
      // body: 'We have received a push message',
      // icon: gon.gitlab_logo,
      body: 'We have received a push message',
      icon: '/test/test.png',
      tag: 'pipeline-notification-worker',
    }),
  );
}

self.addEventListener('install', () => {
  console.log('PipelineNotificationWorker install');
});

self.addEventListener('push', onPush);

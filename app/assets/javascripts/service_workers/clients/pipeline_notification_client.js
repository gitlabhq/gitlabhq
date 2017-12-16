function urlBase64ToUint8Array(base64String) {
  const padding = '='.repeat((4 - base64String.length % 4) % 4);
  const base64 = (base64String + padding)
.replace(/\-/g, '+')
    .replace(/_/g, '/')
  ;
  const rawData = window.atob(base64);
  
  return Uint8Array.from([...rawData].map((char) => char.charCodeAt(0)));
}

export default {
  worker: navigator.serviceWorker,
  workerPath: gon.pipeline_notification_worker_path,
  subscriptionOptions: {
    userVisibleOnly: true,
    applicationServerKey: urlBase64ToUint8Array(
      gon.vapid_key,
    ),
  },
  registration: {},

  init() {
    if (!navigator.serviceWorker) throw new Error('Your browser does not support service workers');

    return this.requestNotificationPermission()
      .then(() => this.register());
  },

  register() {
    return this.worker.register(this.workerPath)
      .then((registration) => {
        this.registration = registration;
      });
  },

  getSubscription() {
    return this.registration.pushManager.getSubscription();
  },

  subscribe() {
    return this.registration.pushManager.subscribe(this.subscriptionOptions);
  },

  requestNotificationPermission() {
    return new Promise((resolve, reject) => {
      const permissionResult = Notification.requestPermission(resolve);

      if (permissionResult) permissionResult.then(resolve).catch(reject);
    })
    .then((permissionResult) => {
      if (permissionResult !== 'granted') throw new Error('Notification permission request declined.');
    });
  },
};

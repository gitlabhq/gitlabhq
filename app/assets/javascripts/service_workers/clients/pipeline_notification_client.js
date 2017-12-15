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
      'BMV-YKtRZpthj5tS1sW4BBaNEqZ67gAQYH_lFLR156QD1pi4TJGZGw46rCBFbFoqV2cMNI6ilD9PZ3DPPt2nEdI',
    ),
  },

  init() {
    if (!navigator.serviceWorker) throw new Error('Your browser does not support service workers');

    return this.install();
  },

  install() {
    return this.requestNotificationPermission()
      .then(() => this.worker.register(this.workerPath))
      .then((registration) => {
        console.log('PipelineNotificationClient install', registration);

        return registration;
      })
      .then(registration => registration.pushManager.subscribe(this.subscriptionOptions))
      .then((pushSubscription) => {
        console.log('PipelineNotificationClient pushSubscription', pushSubscription.toJSON());
      });
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

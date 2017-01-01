(() => {
  const global = window.gl || (window.gl = {});

  class ServiceWorkerClient {
    constructor() {
      if (!navigator.serviceWorker) throw new ReferenceError('Your browser does not support service workers');

      this.worker = navigator.serviceWorker;
      this.cacheWorkerPath = gon.cache_worker_path;
      this.assetPaths = gon.asset_paths;
    }

    install() {
      this.worker.register(this.cacheWorkerPath)
        .then((registration) => {
          console.log('registration successful!', registration);
          this.sendMessage(registration.active, {
            type: 'add_assets',
            data: this.assetPaths,
          });
        })
        .catch((err) => {
          console.log('registration failed!', err);
        });
    }

    sendMessage(client = this.worker.controller, message, transferable = []) {
      return new Promise((resolve, reject) => {
        const messageChannel = new MessageChannel();

        messageChannel.port1.onmessage = event => this.receiveReply(event, message, resolve, reject);

        client.postMessage(message, [messageChannel.port2].concat(transferable));
      });
    }

    receiveReply(event, message, resolve, reject) {
      console.log('reply received', event, message);
      resolve();
    }
  }

  global.ServiceWorkerClient = ServiceWorkerClient;

  $(() => {
    if (global.serviceWorkerClient) return;
    global.serviceWorkerClient = new global.ServiceWorkerClient();
    global.serviceWorkerClient.install();
  });
})();

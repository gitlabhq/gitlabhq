class AjaxCache {
  constructor() {
    this.internalStorage = { };
    this.pendingRequests = { };
  }

  get(endpoint) {
    return this.internalStorage[endpoint];
  }

  hasData(endpoint) {
    return Object.prototype.hasOwnProperty.call(this.internalStorage, endpoint);
  }

  remove(endpoint) {
    delete this.internalStorage[endpoint];
  }

  retrieve(endpoint) {
    if (this.hasData(endpoint)) {
      return Promise.resolve(this.get(endpoint));
    }

    let pendingRequest = this.pendingRequests[endpoint];

    if (!pendingRequest) {
      pendingRequest = new Promise((resolve, reject) => {
        // jQuery 2 is not Promises/A+ compatible (missing catch)
        $.ajax(endpoint) // eslint-disable-line promise/catch-or-return
        .then(data => resolve(data),
          (jqXHR, textStatus, errorThrown) => {
            const error = new Error(`${endpoint}: ${errorThrown}`);
            error.textStatus = textStatus;
            reject(error);
          },
        );
      })
      .then((data) => {
        this.internalStorage[endpoint] = data;
        delete this.pendingRequests[endpoint];
      })
      .catch((error) => {
        delete this.pendingRequests[endpoint];
        throw error;
      });

      this.pendingRequests[endpoint] = pendingRequest;
    }

    return pendingRequest.then(() => this.get(endpoint));
  }
}

export default new AjaxCache();

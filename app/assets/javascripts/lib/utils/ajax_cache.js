const AjaxCache = {
  internalStorage: { },
  get(endpoint) {
    return this.internalStorage[endpoint];
  },
  hasData(endpoint) {
    return Object.prototype.hasOwnProperty.call(this.internalStorage, endpoint);
  },
  purge(endpoint) {
    delete this.internalStorage[endpoint];
  },
  retrieve(endpoint) {
    if (AjaxCache.hasData(endpoint)) {
      return Promise.resolve(AjaxCache.get(endpoint));
    }

    return new Promise((resolve, reject) => {
      $.ajax(endpoint) // eslint-disable-line promise/catch-or-return
      .then(data => resolve(data),
        (jqXHR, textStatus, errorThrown) => {
          const error = new Error(`${endpoint}: ${errorThrown}`);
          error.textStatus = textStatus;
          reject(error);
        },
      );
    })
    .then((data) => { this.internalStorage[endpoint] = data; })
    .then(() => AjaxCache.get(endpoint));
  },
};

export default AjaxCache;

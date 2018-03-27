import axios from './axios_utils';
import Cache from './cache';

class AjaxCache extends Cache {
  constructor() {
    super();
    this.pendingRequests = { };
  }

  override(endpoint, data) {
    this.internalStorage[endpoint] = data;
  }

  retrieve(endpoint, forceRetrieve) {
    if (this.hasData(endpoint) && !forceRetrieve) {
      return Promise.resolve(this.get(endpoint));
    }

    let pendingRequest = this.pendingRequests[endpoint];

    if (!pendingRequest) {
      pendingRequest = axios.get(endpoint)
        .then(({ data }) => {
          this.internalStorage[endpoint] = data;
          delete this.pendingRequests[endpoint];
        })
        .catch((e) => {
          const error = new Error(`${endpoint}: ${e.message}`);
          error.textStatus = e.message;

          delete this.pendingRequests[endpoint];
          throw error;
        });

      this.pendingRequests[endpoint] = pendingRequest;
    }

    return pendingRequest.then(() => this.get(endpoint));
  }
}

export default new AjaxCache();

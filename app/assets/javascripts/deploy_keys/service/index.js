import axios from '~/lib/utils/axios_utils';

export default class DeployKeysService {
  constructor(endpoint) {
    this.axios = axios.create({
      baseURL: endpoint,
    });
  }

  getKeys() {
    return this.axios.get()
      .then(response => response.data);
  }

  enableKey(id) {
    return this.axios.put(`${id}/enable`)
      .then(response => response.data);
  }

  disableKey(id) {
    return this.axios.put(`${id}/disable`)
      .then(response => response.data);
  }
}

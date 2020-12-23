import axios from '~/lib/utils/axios_utils';

export default class DeployKeysService {
  constructor(endpoint) {
    this.endpoint = endpoint;
  }

  getKeys() {
    return axios.get(this.endpoint).then((response) => response.data);
  }

  enableKey(id) {
    return axios.put(`${this.endpoint}/${id}/enable`).then((response) => response.data);
  }

  disableKey(id) {
    return axios.put(`${this.endpoint}/${id}/disable`).then((response) => response.data);
  }
}

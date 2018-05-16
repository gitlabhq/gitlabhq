import axios from '~/lib/utils/axios_utils';

export default class DeployKeysService {
  constructor(endpoint) {
<<<<<<< HEAD
    this.endpoint = endpoint;

    this.resource = Vue.resource(`${this.endpoint}{/id}`, {}, {
      enable: {
        method: 'PUT',
        url: `${this.endpoint}{/id}/enable`,
      },
      disable: {
        method: 'PUT',
        url: `${this.endpoint}{/id}/disable`,
      },
=======
    this.axios = axios.create({
      baseURL: endpoint,
>>>>>>> master
    });
  }

  getKeys() {
<<<<<<< HEAD
    return this.resource.get()
      .then(response => response.json());
=======
    return this.axios.get()
      .then(response => response.data);
>>>>>>> master
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

import axios from '~/lib/utils/axios_utils';

export default class DeployKeysService {
  constructor(endpoint) {
<<<<<<< HEAD
    this.axios = axios.create({
      baseURL: endpoint,
    });
  }

  getKeys() {
    return this.axios.get()
      .then(response => response.data);
=======
    this.endpoint = endpoint;

    this.resource = Vue.resource(
      `${this.endpoint}{/id}`,
      {},
      {
        enable: {
          method: 'PUT',
          url: `${this.endpoint}{/id}/enable`,
        },
        disable: {
          method: 'PUT',
          url: `${this.endpoint}{/id}/disable`,
        },
      },
    );
  }

  getKeys() {
    return this.resource.get().then(response => response.json());
>>>>>>> f67fa26c271... Undo unrelated changes from b1fa486b74875df8cddb4aab8f6d31c036b38137
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

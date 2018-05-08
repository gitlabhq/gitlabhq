import Vue from 'vue';
import VueResource from 'vue-resource';

Vue.use(VueResource);

export default class DeployKeysService {
  constructor(endpoint) {
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
  }

  enableKey(id) {
    return this.resource.enable({ id }, {});
  }

  disableKey(id) {
    return this.resource.disable({ id }, {});
  }
}

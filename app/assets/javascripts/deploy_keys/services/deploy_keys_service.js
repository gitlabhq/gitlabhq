import Vue from 'vue';
import VueResource from 'vue-resource';

Vue.use(VueResource);

export default class DeployKeysService {
  constructor(endpoint) {
    this.endpoint = Vue.resource(endpoint);
  }

  get() {
    return this.endpoint.get();
  }
}

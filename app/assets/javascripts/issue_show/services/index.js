import Vue from 'vue';
import VueResource from 'vue-resource';

Vue.use(VueResource);

export default class Service {
  constructor(endpoint) {
    this.endpoint = endpoint;

    this.resource = Vue.resource(this.endpoint);
  }

  getData() {
    return this.resource.get();
  }
}

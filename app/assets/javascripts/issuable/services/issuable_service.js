import Vue from 'vue';
import VueResource from 'vue-resource';

Vue.use(VueResource);

export default class IssuableService {
  constructor(endpoint) {
    this.endpoint = endpoint;
  }

  get() {
    return Vue.http.get(this.endpoint);
  }
}

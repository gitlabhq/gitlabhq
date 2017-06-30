import Vue from 'vue';
import VueResource from 'vue-resource';

Vue.use(VueResource);

export default class MonitoringService {
  constructor(endpoint) {
    this.graphs = Vue.resource(endpoint);
  }

  get() {
    return this.graphs.get();
  }

  // eslint-disable-next-line class-methods-use-this
  getDeploymentData(endpoint) {
    return Vue.http.get(endpoint);
  }
}

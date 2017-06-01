/* eslint-disable class-methods-use-this */
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

  getDeploymentData(endpoint) {
    return Vue.http.get(endpoint);
  }
}

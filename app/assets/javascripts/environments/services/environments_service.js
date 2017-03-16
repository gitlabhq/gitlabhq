/* eslint-disable class-methods-use-this */
import Vue from 'vue';

export default class EnvironmentsService {
  constructor(endpoint) {
    this.environments = Vue.resource(endpoint);
  }

  get() {
    return this.environments.get();
  }

  getDeployBoard(endpoint) {
    return Vue.http.get(endpoint);
  }

  postAction(endpoint) {
    return Vue.http.post(endpoint, {}, { emulateJSON: true });
  }
}

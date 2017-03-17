/* eslint-disable class-methods-use-this */
import Vue from 'vue';

export default class EnvironmentsService {
  constructor(endpoint) {
    this.environments = Vue.resource(endpoint);
  }

  get(scope, page) {
    return this.environments.get({ scope, page });
  }

  postAction(endpoint) {
    return Vue.http.post(endpoint, {}, { emulateJSON: true });
  }
}

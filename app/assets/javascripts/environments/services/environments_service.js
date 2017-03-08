/* eslint-disable class-methods-use-this*/
const Vue = require('vue');

class EnvironmentsService {
  constructor(endpoint) {
    this.environments = Vue.resource(endpoint);
  }

  get() {
    return this.environments.get();
  }

  getDeployBoard(endpoint) {
    return Vue.http.get(endpoint);
  }
}

module.exports = EnvironmentsService;

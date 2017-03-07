const Vue = require('vue');

class EnvironmentsService {
  constructor(endpoint) {
    this.environments = Vue.resource(endpoint);
  }

  get() {
    return this.environments.get();
  }
}

module.exports = EnvironmentsService;

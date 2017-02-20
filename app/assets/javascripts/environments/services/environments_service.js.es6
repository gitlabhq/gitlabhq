const Vue = require('vue');

class EnvironmentsService {
  constructor(endpoint) {
    this.environments = Vue.resource(endpoint);
  }

  all() {
    return this.environments.get();
  }
}

module.exports = EnvironmentsService;

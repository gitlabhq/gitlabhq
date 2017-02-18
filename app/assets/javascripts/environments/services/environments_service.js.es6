const Vue = require('vue');

class EnvironmentsService {
  constructor(endpoint) {
    this.environments = Vue.resource(endpoint);

    this.deployBoard = Vue.resource('environments/{id}/status.json');
  }

  all() {
    return this.environments.get();
  }

  getDeployBoard(environmentID) {
    return this.deployBoard.get({ id: environmentID });
  }
}

module.exports = EnvironmentsService;

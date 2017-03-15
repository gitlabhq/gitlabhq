<<<<<<< HEAD
/* eslint-disable class-methods-use-this*/
const Vue = require('vue');
=======
/* eslint-disable class-methods-use-this */
import Vue from 'vue';
>>>>>>> ce/master

export default class EnvironmentsService {
  constructor(endpoint) {
    this.environments = Vue.resource(endpoint);
  }

  get(scope, page) {
    return this.environments.get({ scope, page });
  }
<<<<<<< HEAD

  getDeployBoard(endpoint) {
    return Vue.http.get(endpoint);
  }
}
=======
>>>>>>> ce/master

  postAction(endpoint) {
    return Vue.http.post(endpoint, {}, { emulateJSON: true });
  }
}

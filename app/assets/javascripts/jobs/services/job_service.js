import Vue from 'vue';
import VueResource from 'vue-resource';

Vue.use(VueResource);

export default class JobService {
  constructor(endpoint) {
    this.job = Vue.resource(endpoint);
  }

  getJob() {
    return this.job.get();
  }
}

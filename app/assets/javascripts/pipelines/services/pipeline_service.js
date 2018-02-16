import Vue from 'vue';
import VueResource from 'vue-resource';

Vue.use(VueResource);

export default class PipelineService {
  constructor(endpoint) {
    this.pipeline = Vue.resource(endpoint);
  }

  getPipeline() {
    return this.pipeline.get();
  }

  // eslint-disable-next-line
  postAction(endpoint) {
    return Vue.http.post(`${endpoint}.json`);
  }

  static getSecurityReport(endpoint) {
    return Vue.http.get(endpoint);
  }
}

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

  // eslint-disable-next-line
  getJobLog(endpoint) {
    const traceEndpoint = `${endpoint}/raw`;
    return Vue.http.get(traceEndpoint);
  }

  // eslint-disable-next-line
  getJobData(endpoint) {
    return Vue.http.get(endpoint);
  }
}

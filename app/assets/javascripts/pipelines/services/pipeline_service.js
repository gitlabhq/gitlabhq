import axios from '../../lib/utils/axios_utils';

export default class PipelineService {
  constructor(endpoint) {
    this.pipeline = endpoint;
  }

  getPipeline() {
    return axios.get(this.pipeline);
  }

  // eslint-disable-next-line class-methods-use-this
  postAction(endpoint) {
    return axios.post(`${endpoint}.json`);
  }

  static getSecurityReport(endpoint) {
    return axios.get(endpoint);
  }
}

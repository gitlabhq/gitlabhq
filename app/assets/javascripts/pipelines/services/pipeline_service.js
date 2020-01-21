import axios from '../../lib/utils/axios_utils';

export default class PipelineService {
  constructor(endpoint) {
    this.pipeline = endpoint;
  }

  getPipeline(params) {
    return axios.get(this.pipeline, { params });
  }

  // eslint-disable-next-line class-methods-use-this
  deleteAction(endpoint) {
    return axios.delete(`${endpoint}.json`);
  }

  // eslint-disable-next-line class-methods-use-this
  postAction(endpoint) {
    return axios.post(`${endpoint}.json`);
  }
}

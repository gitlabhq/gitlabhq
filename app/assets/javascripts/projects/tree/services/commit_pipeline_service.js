import axios from '~/lib/utils/axios_utils';

export default class CommitPipelineService {
  constructor(endpoint) {
    this.endpoint = endpoint;
  }

  fetchData() {
    return axios.get(this.endpoint);
  }
}

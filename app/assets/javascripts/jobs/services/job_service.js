import axios from '../../lib/utils/axios_utils';

export default class JobService {
  constructor(endpoint) {
    this.job = endpoint;
  }

  getJob() {
    return axios.get(this.job);
  }
}

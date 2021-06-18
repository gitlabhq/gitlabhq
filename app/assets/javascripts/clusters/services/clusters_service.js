import axios from '../../lib/utils/axios_utils';

export default class ClusterService {
  constructor(options = {}) {
    this.options = options;
  }

  fetchClusterStatus() {
    return axios.get(this.options.endpoint);
  }

  fetchClusterEnvironments() {
    return axios.get(this.options.clusterEnvironmentsEndpoint);
  }

  static updateCluster(endpoint, data) {
    return axios.put(endpoint, data);
  }
}

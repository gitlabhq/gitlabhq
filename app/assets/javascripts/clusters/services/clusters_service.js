import axios from '../../lib/utils/axios_utils';

export default class ClusterService {
  constructor(options = {}) {
    this.options = options;
    this.appInstallEndpointMap = {
      helm: this.options.installHelmEndpoint,
      ingress: this.options.installIngressEndpoint,
      runner: this.options.installRunnerEndpoint,
    };
  }

  fetchData() {
    return axios.get(this.options.endpoint);
  }

  installApplication(appId) {
    return axios.post(this.appInstallEndpointMap[appId]);
  }
}

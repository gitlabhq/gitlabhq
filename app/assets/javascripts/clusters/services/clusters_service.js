import axios from '../../lib/utils/axios_utils';

export default class ClusterService {
  constructor(options = {}) {
    this.options = options;
    this.appInstallEndpointMap = {
      helm: this.options.installHelmEndpoint,
      ingress: this.options.installIngressEndpoint,
      runner: this.options.installRunnerEndpoint,
      prometheus: this.options.installPrometheusEndpoint,
      jupyter: this.options.installJupyterEndpoint,
    };
  }

  fetchData() {
    return axios.get(this.options.endpoint);
  }

  installApplication(appId, params) {
    return axios.post(this.appInstallEndpointMap[appId], params);
  }

  static updateCluster(endpoint, data) {
    return axios.put(endpoint, data);
  }
}

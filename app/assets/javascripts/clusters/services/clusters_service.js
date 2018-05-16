import axios from '../../lib/utils/axios_utils';
import { JUPYTER } from '../constants';

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

  installApplication(appId) {
    const data = {};

    if (appId === JUPYTER) {
      data.hostname = document.getElementById('jupyter-hostname').value;
    }

    return axios.post(this.appInstallEndpointMap[appId], data);
  }

  static updateCluster(endpoint, data) {
    return axios.put(endpoint, data);
  }
}

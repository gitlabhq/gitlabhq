import axios from '../../lib/utils/axios_utils';

export default class ClusterService {
  constructor(options = {}) {
    this.options = options;
    this.appInstallEndpointMap = {
      helm: this.options.installHelmEndpoint,
      ingress: this.options.installIngressEndpoint,
      cert_manager: this.options.installCertManagerEndpoint,
      runner: this.options.installRunnerEndpoint,
      prometheus: this.options.installPrometheusEndpoint,
      jupyter: this.options.installJupyterEndpoint,
      knative: this.options.installKnativeEndpoint,
    };
    this.appUpdateEndpointMap = {
      knative: this.options.updateKnativeEndpoint,
    };
  }

  fetchData() {
    return axios.get(this.options.endpoint);
  }

  installApplication(appId, params) {
    return axios.post(this.appInstallEndpointMap[appId], params);
  }

  updateApplication(appId, params) {
    return axios.patch(this.appUpdateEndpointMap[appId], params);
  }

  uninstallApplication(appId, params) {
    return axios.delete(this.appInstallEndpointMap[appId], params);
  }

  static updateCluster(endpoint, data) {
    return axios.put(endpoint, data);
  }
}

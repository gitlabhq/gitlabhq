import axios from 'axios';
import setAxiosCsrfToken from '../../lib/utils/axios_utils';

export default class ClusterService {
  constructor(options = {}) {
    setAxiosCsrfToken();

    this.options = options;
    this.appInstallEndpointMap = {
      helm: this.options.installHelmEndpoint,
    };
  }

  fetchData() {
    return axios.get(this.options.endpoint);
  }

  installApplication(appId) {
    const endpoint = this.appInstallEndpointMap[appId];
    return axios.post(endpoint);
  }
}

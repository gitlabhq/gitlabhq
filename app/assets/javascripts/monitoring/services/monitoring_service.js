import axios from '../../lib/utils/axios_utils';
import statusCodes from '../../lib/utils/http_status';
import { backOff } from '../../lib/utils/common_utils';
import { s__ } from '../../locale';

const MAX_REQUESTS = 3;

function backOffRequest(makeRequestCallback) {
  let requestCounter = 0;
  return backOff((next, stop) => {
    makeRequestCallback().then((resp) => {
      if (resp.status === statusCodes.NO_CONTENT) {
        requestCounter += 1;
        if (requestCounter < MAX_REQUESTS) {
          next();
        } else {
          stop(new Error('Failed to connect to the prometheus server'));
        }
      } else {
        stop(resp);
      }
    }).catch(stop);
  });
}

export default class MonitoringService {
  constructor({ metricsEndpoint, deploymentEndpoint, environmentsEndpoint }) {
    this.metricsEndpoint = metricsEndpoint;
    this.deploymentEndpoint = deploymentEndpoint;
    this.environmentsEndpoint = environmentsEndpoint;
  }

  getGraphsData() {
    return backOffRequest(() => axios.get(this.metricsEndpoint))
      .then(resp => resp.data)
      .then((response) => {
        if (!response || !response.data) {
          throw new Error(s__('Metrics|Unexpected metrics data response from prometheus endpoint'));
        }
        return response.data;
      });
  }

  getDeploymentData() {
    if (!this.deploymentEndpoint) {
      return Promise.resolve([]);
    }
    return backOffRequest(() => axios.get(this.deploymentEndpoint))
      .then(resp => resp.data)
      .then((response) => {
        if (!response || !response.deployments) {
          throw new Error(s__('Metrics|Unexpected deployment data response from prometheus endpoint'));
        }
        return response.deployments;
      });
  }

  getEnvironmentsData() {
    return axios.get(this.environmentsEndpoint)
    .then(resp => resp.data)
    .then((response) => {
      if (!response || !response.environments) {
        throw new Error(s__('Metrics|There was an error fetching the environments data, please try again'));
      }
      return response.environments;
    });
  }
}

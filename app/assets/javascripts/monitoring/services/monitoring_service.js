import Vue from 'vue';
import VueResource from 'vue-resource';
import statusCodes from '../../lib/utils/http_status';
import { backOff } from '../../lib/utils/common_utils';

Vue.use(VueResource);

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
  constructor({ metricsEndpoint, deploymentEndpoint }) {
    this.metricsEndpoint = metricsEndpoint;
    this.deploymentEndpoint = deploymentEndpoint;
  }

  getGraphsData() {
    return backOffRequest(() => Vue.http.get(this.metricsEndpoint))
      .then(resp => resp.json())
      .then((response) => {
        if (!response || !response.data) {
          throw new Error('Unexpected metrics data response from prometheus endpoint');
        }
        return response.data;
      });
  }

  getDeploymentData() {
    return backOffRequest(() => Vue.http.get(this.deploymentEndpoint))
      .then(resp => resp.json())
      .then((response) => {
        if (!response || !response.deployments) {
          throw new Error('Unexpected deployment data response from prometheus endpoint');
        }
        return response.deployments;
      });
  }
}

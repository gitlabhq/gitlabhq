import axios from '~/lib/utils/axios_utils';

export default class AlertsService {
  constructor({ alertsEndpoint }) {
    this.alertsEndpoint = alertsEndpoint;
  }

  getAlerts() {
    return axios.get(this.alertsEndpoint).then(resp => resp.data);
  }

  createAlert({ prometheus_metric_id, operator, threshold }) {
    return axios
      .post(this.alertsEndpoint, { prometheus_metric_id, operator, threshold })
      .then(resp => resp.data);
  }

  // eslint-disable-next-line class-methods-use-this
  readAlert(alertPath) {
    return axios.get(alertPath).then(resp => resp.data);
  }

  // eslint-disable-next-line class-methods-use-this
  updateAlert(alertPath, { operator, threshold }) {
    return axios.put(alertPath, { operator, threshold }).then(resp => resp.data);
  }

  // eslint-disable-next-line class-methods-use-this
  deleteAlert(alertPath) {
    return axios.delete(alertPath).then(resp => resp.data);
  }
}

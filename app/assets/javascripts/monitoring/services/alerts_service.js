import axios from '~/lib/utils/axios_utils';

const mapAlert = ({ runbook_url, ...alert }) => {
  return { runbookUrl: runbook_url, ...alert };
};

export default class AlertsService {
  constructor({ alertsEndpoint }) {
    this.alertsEndpoint = alertsEndpoint;
  }

  getAlerts() {
    return axios.get(this.alertsEndpoint).then((resp) => mapAlert(resp.data));
  }

  createAlert({ prometheus_metric_id, operator, threshold, runbookUrl }) {
    return axios
      .post(this.alertsEndpoint, {
        prometheus_metric_id,
        operator,
        threshold,
        runbook_url: runbookUrl,
      })
      .then((resp) => mapAlert(resp.data));
  }

  // eslint-disable-next-line class-methods-use-this
  readAlert(alertPath) {
    return axios.get(alertPath).then((resp) => mapAlert(resp.data));
  }

  // eslint-disable-next-line class-methods-use-this
  updateAlert(alertPath, { operator, threshold, runbookUrl }) {
    return axios
      .put(alertPath, { operator, threshold, runbook_url: runbookUrl })
      .then((resp) => mapAlert(resp.data));
  }

  // eslint-disable-next-line class-methods-use-this
  deleteAlert(alertPath) {
    return axios.delete(alertPath).then((resp) => resp.data);
  }
}

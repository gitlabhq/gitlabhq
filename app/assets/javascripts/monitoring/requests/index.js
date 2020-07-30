import axios from '~/lib/utils/axios_utils';
import statusCodes from '~/lib/utils/http_status';
import { backOff } from '~/lib/utils/common_utils';
import { PROMETHEUS_TIMEOUT } from '../constants';

const backOffRequest = makeRequestCallback =>
  backOff((next, stop) => {
    makeRequestCallback()
      .then(resp => {
        if (resp.status === statusCodes.NO_CONTENT) {
          next();
        } else {
          stop(resp);
        }
      })
      .catch(stop);
  }, PROMETHEUS_TIMEOUT);

export const getDashboard = (dashboardEndpoint, params) =>
  backOffRequest(() => axios.get(dashboardEndpoint, { params })).then(
    axiosResponse => axiosResponse.data,
  );

export const getPrometheusQueryData = (prometheusEndpoint, params) =>
  backOffRequest(() => axios.get(prometheusEndpoint, { params }))
    .then(axiosResponse => axiosResponse.data)
    .then(prometheusResponse => prometheusResponse.data)
    .catch(error => {
      // Prometheus returns errors in specific cases
      // https://prometheus.io/docs/prometheus/latest/querying/api/#format-overview
      const { response = {} } = error;
      if (
        response.status === statusCodes.BAD_REQUEST ||
        response.status === statusCodes.UNPROCESSABLE_ENTITY ||
        response.status === statusCodes.SERVICE_UNAVAILABLE
      ) {
        const { data } = response;
        if (data?.status === 'error' && data?.error) {
          throw new Error(data.error);
        }
      }
      throw error;
    });

// eslint-disable-next-line no-unused-vars
export function getPanelJson(panelPreviewEndpoint, panelPreviewYml) {
  // TODO Use a real backend when it's available
  // https://gitlab.com/gitlab-org/gitlab/-/issues/228758

  // eslint-disable-next-line @gitlab/require-i18n-strings
  return Promise.reject(new Error('API Not implemented.'));
}

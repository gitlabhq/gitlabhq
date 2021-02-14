import axios from '~/lib/utils/axios_utils';
import { backOff } from '~/lib/utils/common_utils';
import statusCodes from '~/lib/utils/http_status';
import { PROMETHEUS_TIMEOUT } from '../constants';

const cancellableBackOffRequest = (makeRequestCallback) =>
  backOff((next, stop) => {
    makeRequestCallback()
      .then((resp) => {
        if (resp.status === statusCodes.NO_CONTENT) {
          next();
        } else {
          stop(resp);
        }
      })
      // If the request is cancelled by axios
      // then consider it as noop so that its not
      // caught by subsequent catches
      .catch((thrown) => (axios.isCancel(thrown) ? undefined : stop(thrown)));
  }, PROMETHEUS_TIMEOUT);

export const getDashboard = (dashboardEndpoint, params) =>
  cancellableBackOffRequest(() => axios.get(dashboardEndpoint, { params })).then(
    (axiosResponse) => axiosResponse.data,
  );

export const getPrometheusQueryData = (prometheusEndpoint, params, opts) =>
  cancellableBackOffRequest(() => axios.get(prometheusEndpoint, { params, ...opts }))
    .then((axiosResponse) => axiosResponse.data)
    .then((prometheusResponse) => prometheusResponse.data)
    .catch((error) => {
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

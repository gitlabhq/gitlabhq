import axios from '~/lib/utils/axios_utils';
import { backOff } from '~/lib/utils/common_utils';
import {
  HTTP_STATUS_BAD_REQUEST,
  HTTP_STATUS_NO_CONTENT,
  HTTP_STATUS_SERVICE_UNAVAILABLE,
  HTTP_STATUS_UNPROCESSABLE_ENTITY,
} from '~/lib/utils/http_status';
import { PROMETHEUS_TIMEOUT } from '../constants';

const cancellableBackOffRequest = (makeRequestCallback) =>
  backOff((next, stop) => {
    makeRequestCallback()
      .then((resp) => {
        if (resp.status === HTTP_STATUS_NO_CONTENT) {
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
        response.status === HTTP_STATUS_BAD_REQUEST ||
        response.status === HTTP_STATUS_UNPROCESSABLE_ENTITY ||
        response.status === HTTP_STATUS_SERVICE_UNAVAILABLE
      ) {
        const { data } = response;
        if (data?.status === 'error' && data?.error) {
          throw new Error(data.error);
        }
      }
      throw error;
    });

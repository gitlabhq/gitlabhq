/* eslint-disable @gitlab/require-i18n-strings */
import axios from '~/lib/utils/axios_utils';

export default {
  updateGenericKey({ endpoint, params }) {
    return axios.put(endpoint, params);
  },
  updatePrometheusKey({ endpoint }) {
    return axios.post(endpoint);
  },
  updateGenericActive({ endpoint, params }) {
    return axios.put(endpoint, params);
  },
  updatePrometheusActive({ endpoint, params: { token, config, url, redirect } }) {
    const data = new FormData();
    data.set('_method', 'put');
    data.set('authenticity_token', token);
    data.set('service[manual_configuration]', config);
    data.set('service[api_url]', url);
    data.set('redirect_to', redirect);

    return axios.post(endpoint, data, {
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
    });
  },
  updateTestAlert({ endpoint, data, authKey }) {
    return axios.post(endpoint, data, {
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${authKey}`,
      },
    });
  },
};

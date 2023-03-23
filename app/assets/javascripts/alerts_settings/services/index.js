import axios from '~/lib/utils/axios_utils';

export default {
  updateGenericActive({ endpoint, params }) {
    return axios.put(endpoint, params);
  },
  updateTestAlert({ endpoint, data, token }) {
    return axios.post(endpoint, data, {
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`, // eslint-disable-line @gitlab/require-i18n-strings
      },
    });
  },
};

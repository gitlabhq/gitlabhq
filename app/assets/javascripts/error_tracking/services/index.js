import axios from '~/lib/utils/axios_utils';

export default {
  getSentryData({ endpoint, params }) {
    return axios.get(endpoint, { params });
  },
  updateErrorStatus(endpoint, status) {
    return axios.put(endpoint, { status });
  },
};

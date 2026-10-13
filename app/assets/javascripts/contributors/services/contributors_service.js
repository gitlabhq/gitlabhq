import axios from '~/lib/utils/axios_utils';

export default {
  fetchChartData(endpoint, params = {}) {
    if (Object.keys(params).length) {
      return axios.get(endpoint, { params });
    }

    return axios.get(endpoint);
  },
};

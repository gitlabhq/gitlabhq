import axios from '~/lib/utils/axios_utils';

export default {
  fetchChartData(endpoint) {
    return axios.get(endpoint);
  },
};

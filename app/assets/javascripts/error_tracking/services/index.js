import axios from '~/lib/utils/axios_utils';

export default {
  getSentryData({ endpoint }) {
    return axios.get(endpoint);
  },
};

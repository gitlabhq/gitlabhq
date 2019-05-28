import axios from '~/lib/utils/axios_utils';

export default {
  getErrorList({ endpoint }) {
    return axios.get(endpoint);
  },
};

import axios from '~/lib/utils/axios_utils';

export default {
  getAlertManagementList({ endpoint }) {
    return axios.get(endpoint);
  },
};

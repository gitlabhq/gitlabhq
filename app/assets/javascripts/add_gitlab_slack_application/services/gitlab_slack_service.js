import axios from 'axios';
import setAxiosCsrfToken from '../../lib/utils/axios_utils';

export default {
  init() {
    setAxiosCsrfToken();
  },

  addToSlack(url, projectId) {
    return axios.get(url, {
      params: {
        project_id: projectId,
      },
    });
  },
};

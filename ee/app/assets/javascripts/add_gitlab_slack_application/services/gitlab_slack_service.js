import axios from '~/lib/utils/axios_utils';

export default {
  addToSlack(url, projectId) {
    return axios.get(url, {
      params: {
        project_id: projectId,
      },
    });
  },
};

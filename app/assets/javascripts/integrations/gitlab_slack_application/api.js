import axios from '~/lib/utils/axios_utils';

export const addProjectToSlack = (url, projectId) => {
  return axios.get(url, {
    params: { project_id: projectId },
  });
};

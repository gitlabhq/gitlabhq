import axios from '~/lib/utils/axios_utils';

export const fetchImportFailures = (failuresPath, { projectId, page, perPage }) => {
  return axios.get(failuresPath, {
    params: {
      project_id: projectId,
      page,
      per_page: perPage,
    },
  });
};

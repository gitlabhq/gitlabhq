import axios from 'axios';

export async function postProjectPipelines(endpoint) {
  const { url } = endpoint;

  return axios({
    method: 'POST',
    baseURL: url,
    url: '/gitlab-org/gitlab-qa/-/pipelines',
    headers: {
      Accept: '*/*',
      'Content-Type': 'application/json; charset=utf-8',
    },
    data: { ref: 'master' },
    validateStatus: (status) => {
      return status === 302;
    },
  });
}

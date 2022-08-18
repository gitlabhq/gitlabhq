import axios from 'axios';

export async function getProjectPipelines(endpoint) {
  const { url } = endpoint;

  return axios({
    method: 'GET',
    baseURL: url,
    url: '/gitlab-org/gitlab-qa/-/pipelines.json',
    headers: { Accept: '*/*' },
    params: {
      scope: 'all',
      page: 1,
    },
  }).then((response) => response.data);
}

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

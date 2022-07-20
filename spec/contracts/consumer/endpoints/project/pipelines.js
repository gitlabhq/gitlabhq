import { request } from 'axios';

export function getProjectPipelines(endpoint) {
  const { url } = endpoint;

  return request({
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

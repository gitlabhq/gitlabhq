import { request } from 'axios';

export function getDiffsMetadata(endpoint) {
  const { url } = endpoint;

  return request({
    method: 'GET',
    baseURL: url,
    url: '/gitlab-org/gitlab-qa/-/merge_requests/1/diffs_metadata.json',
    headers: { Accept: '*/*' },
  }).then((response) => response.data);
}

export function getDiscussions(endpoint) {
  const { url } = endpoint;

  return request({
    method: 'GET',
    baseURL: url,
    url: '/gitlab-org/gitlab-qa/-/merge_requests/1/discussions.json',
    headers: { Accept: '*/*' },
  }).then((response) => response.data);
}

export function getDiffsBatch(endpoint) {
  const { url } = endpoint;

  return request({
    method: 'GET',
    baseURL: url,
    url: '/gitlab-org/gitlab-qa/-/merge_requests/1/diffs_batch.json?page=0',
    headers: { Accept: '*/*' },
  }).then((response) => response.data);
}

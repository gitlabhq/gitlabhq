import axios from '~/lib/utils/axios_utils';
import { buildApiUrl } from '~/api/api_utils';

// the :request_path is loading API-like resources, not part of our REST API.
// https://gitlab.com/gitlab-org/gitlab/-/merge_requests/82784#note_1077703806
const HARBOR_REPOSITORIES_PATH = '/:request_path.json';
const HARBOR_ARTIFACTS_PATH = '/:request_path/:repo_name/artifacts.json';
const HARBOR_TAGS_PATH = '/:request_path/:repo_name/artifacts/:digest/tags.json';

export function getHarborRepositoriesList({ requestPath, limit, page, sort, search = '' }) {
  const url = buildApiUrl(HARBOR_REPOSITORIES_PATH).replace('/:request_path', requestPath);

  return axios.get(url, {
    params: {
      limit,
      page,
      search,
      sort,
    },
  });
}

export function getHarborArtifacts({ requestPath, repoName, limit, page, sort, search = '' }) {
  const url = buildApiUrl(HARBOR_ARTIFACTS_PATH)
    .replace('/:request_path', requestPath)
    .replace(':repo_name', repoName);

  return axios.get(url, {
    params: {
      limit,
      page,
      search,
      sort,
    },
  });
}

export function getHarborTags({ requestPath, repoName, digest, page }) {
  const url = buildApiUrl(HARBOR_TAGS_PATH)
    .replace('/:request_path', requestPath)
    .replace(':repo_name', repoName)
    .replace(':digest', digest);

  return axios.get(url, {
    params: {
      page,
    },
  });
}

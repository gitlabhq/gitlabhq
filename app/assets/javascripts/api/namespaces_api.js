import { buildApiUrl } from '~/api/api_utils';
import axios from '~/lib/utils/axios_utils';

const NAMESPACE_EXISTS_PATH = '/api/:version/namespaces/:id/exists';

export function getGroupPathAvailability(groupPath, parentId, axiosOptions = {}) {
  const url = buildApiUrl(NAMESPACE_EXISTS_PATH).replace(':id', encodeURIComponent(groupPath));

  return axios.get(url, {
    params: { parent_id: parentId, ...axiosOptions.params },
    ...axiosOptions,
  });
}

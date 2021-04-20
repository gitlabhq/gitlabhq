import { buildApiUrl } from '~/api/api_utils';
import axios from '~/lib/utils/axios_utils';

const NAMESPACE_EXISTS_PATH = '/api/:version/namespaces/:id/exists';

export default function fetchGroupPathAvailability(groupPath, parentId) {
  const url = buildApiUrl(NAMESPACE_EXISTS_PATH).replace(':id', encodeURIComponent(groupPath));

  return axios.get(url, {
    params: { parent_id: parentId },
  });
}

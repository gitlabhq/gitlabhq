import axios from '../lib/utils/axios_utils';
import { buildApiUrl } from './api_utils';

export const STOP_STALE_ENVIRONMENTS_PATH = '/api/:version/projects/:id/environments/stop_stale';

// eslint-disable-next-line max-params
export function stopStaleEnvironments(projectId, before, query, options) {
  const url = buildApiUrl(STOP_STALE_ENVIRONMENTS_PATH).replace(':id', projectId);
  const defaults = {
    before: before.toISOString(),
  };

  return axios.post(url, null, {
    params: Object.assign(defaults, options),
  });
}

import axios from '~/lib/utils/axios_utils';
import { buildApiUrl } from './api_utils';

const OFFLINE_EXPORTS_PATH = '/api/:version/offline_exports';

export function getOfflineExports(params = {}) {
  const url = buildApiUrl(OFFLINE_EXPORTS_PATH);

  return axios.get(url, { params });
}

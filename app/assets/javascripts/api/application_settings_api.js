import axios from '../lib/utils/axios_utils';
import { buildApiUrl } from './api_utils';

const APPLICATION_SETTINGS_PATH = '/api/:version/application/settings';

export function getApplicationSettings() {
  const url = buildApiUrl(APPLICATION_SETTINGS_PATH);
  return axios.get(url);
}

export function updateApplicationSettings(data) {
  const url = buildApiUrl(APPLICATION_SETTINGS_PATH);
  return axios.put(url, data);
}

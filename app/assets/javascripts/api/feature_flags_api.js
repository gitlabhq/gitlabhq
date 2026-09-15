import axios from '../lib/utils/axios_utils';
import { buildApiUrl } from './api_utils';

const FEATURE_FLAGS_SETTINGS_PATH = '/api/:version/projects/:id/feature_flags_settings';

const settingsUrl = (projectPath) =>
  buildApiUrl(FEATURE_FLAGS_SETTINGS_PATH).replace(':id', encodeURIComponent(projectPath));

export function updateFeatureFlagsSettings(projectPath, { minimumRole }) {
  return axios.put(settingsUrl(projectPath), { minimum_role: minimumRole });
}

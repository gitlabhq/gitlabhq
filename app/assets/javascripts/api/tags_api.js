import axios from '../lib/utils/axios_utils';
import { buildApiUrl } from './api_utils';

const TAG_PATH = '/api/:version/projects/:id/repository/tags/:tag_name';

export function getTag(id, tagName) {
  const url = buildApiUrl(TAG_PATH)
    .replace(':id', encodeURIComponent(id))
    .replace(':tag_name', encodeURIComponent(tagName));

  return axios.get(url);
}

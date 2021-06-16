import axios from '../lib/utils/axios_utils';
import { buildApiUrl } from './api_utils';

const MARKDOWN_PATH = '/api/:version/markdown';

export function getMarkdown(options) {
  const url = buildApiUrl(MARKDOWN_PATH);
  return axios.post(url, {
    ...options,
  });
}

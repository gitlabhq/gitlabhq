import { joinPaths } from '../lib/utils/url_utility';

export function buildApiUrl(url) {
  return joinPaths('/', gon.relative_url_root || '', url.replace(':version', gon.api_version));
}

import { joinPaths } from '../lib/utils/url_utility';

export function buildApiUrl(url) {
  // eslint-disable-next-line @gitlab/no-hardcoded-urls -- Low level util used for REST API URLs
  return joinPaths('/', gon.relative_url_root || '', url.replace(':version', gon.api_version));
}

import { joinPaths, escapeFileUrl } from '~/lib/utils/url_utility';

export function generateHistoryUrl(historyLink, path, refType) {
  const url = new URL(window.location.href);

  url.pathname = joinPaths(historyLink, path ? escapeFileUrl(path) : '');

  if (refType) {
    url.searchParams.set('ref_type', refType);
  }

  return url;
}

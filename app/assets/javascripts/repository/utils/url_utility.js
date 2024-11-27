import { joinPaths, escapeFileUrl, removeParams } from '~/lib/utils/url_utility';

export function generateHistoryUrl(historyLink, path, refType) {
  const url = new URL(window.location.href);

  url.pathname = joinPaths(
    removeParams(['ref_type'], historyLink),
    path ? escapeFileUrl(path) : '',
  );

  if (refType && !url.searchParams.get('ref_type')) {
    url.searchParams.set('ref_type', refType);
  }

  return url;
}

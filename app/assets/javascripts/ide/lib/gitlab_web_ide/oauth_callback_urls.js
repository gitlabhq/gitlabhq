import { joinPaths } from '~/lib/utils/url_utility';
import { logError } from '~/lib/logger';
import { WEB_IDE_OAUTH_CALLBACK_URL_PATH, IDE_PATH } from '../../constants';

/**
 * @returns callback URL constructed from current window url
 */
export function getOAuthCallbackUrl() {
  const url = window.location.href;

  // We don't rely on `gon.gitlab_url` and `gon.relative_url_root` here because these may not be configured correctly
  // or we're visiting the instance through a proxy.
  // Instead, we split on the `/-/ide` in the `href` and use the first part as the base URL.
  const baseUrl = url.split(IDE_PATH, 2)[0];
  const callbackUrl = joinPaths(baseUrl, WEB_IDE_OAUTH_CALLBACK_URL_PATH);

  return callbackUrl;
}

const parseCallbackUrl = (urlStr) => {
  let callbackUrl;

  try {
    callbackUrl = new URL(urlStr);
  } catch {
    // Not a valid URL. Nothing to do here.
    return undefined;
  }

  // If we're an unexpected callback URL
  if (!callbackUrl.pathname.endsWith(WEB_IDE_OAUTH_CALLBACK_URL_PATH)) {
    return {
      base: joinPaths(callbackUrl.origin, '/'),
      url: urlStr,
    };
  }

  // Else, trim the expected bit to get the origin + relative_url_root
  const callbackRelativePath = callbackUrl.pathname.substring(
    0,
    callbackUrl.pathname.length - WEB_IDE_OAUTH_CALLBACK_URL_PATH.length,
  );
  const baseUrl = new URL(callbackUrl);
  baseUrl.pathname = callbackRelativePath;
  baseUrl.hash = '';
  baseUrl.search = '';

  return {
    base: joinPaths(baseUrl.toString(), '/'),
    url: urlStr,
  };
};

export const parseCallbackUrls = (callbackUrlsJson) => {
  if (!callbackUrlsJson) {
    return [];
  }

  let urls;

  try {
    urls = JSON.parse(callbackUrlsJson);
  } catch {
    // why: We dont want to translate console errors
    // eslint-disable-next-line @gitlab/require-i18n-strings
    logError('Failed to parse callback URLs JSON');
    return [];
  }

  if (!urls || !Array.isArray(urls)) {
    return [];
  }

  return urls.map(parseCallbackUrl).filter(Boolean);
};

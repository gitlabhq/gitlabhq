import { setUrlFragment } from '~/lib/utils/url_utility';

// A deep-link fragment (e.g. #L7) is never sent to the server, so it is absent from the
// server-built 2FA form action and final redirect. The browser keeps it in the address bar
// through sign-in's fragment-less redirects, so re-attach it here to carry it to the destination.
export function applyDeepLinkFragment(url) {
  const fragment = document.location.hash;

  if (!url || !fragment) {
    return url;
  }

  return setUrlFragment(url, fragment);
}

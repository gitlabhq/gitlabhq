import { setCookie, removeCookie, getCookie } from '~/lib/utils/common_utils';

// Cookie used to opt in/out of GitLab Next (canary). It is scoped to the root
// domain so it is shared across all gitlab.com subdomains (e.g.
// next.gitlab.com).
export const GITLAB_NEXT_COOKIE = 'gitlab_canary';
export const GITLAB_NEXT_COOKIE_DOMAIN = '.gitlab.com';

const COOKIE_OPTIONS = { domain: GITLAB_NEXT_COOKIE_DOMAIN, path: '/' };

/**
 * Whether GitLab Next (canary) is currently opted into via the cookie.
 *
 * @returns {boolean}
 */
export const isGitlabNextEnabled = () => getCookie(GITLAB_NEXT_COOKIE) === 'true';

/**
 * Opt in or out of GitLab Next by setting or removing the canary cookie.
 *
 * @param {boolean} enabled - Whether to enable GitLab Next.
 */
export const setGitlabNext = (enabled) => {
  if (enabled) {
    setCookie(GITLAB_NEXT_COOKIE, 'true', COOKIE_OPTIONS);
  } else {
    // A cookie can only be removed by matching the exact (name, domain, path)
    // it was set with. There are two variants in the wild:
    //   - domain `.gitlab.com`, path `/`: set by next.gitlab.com and by the
    //     current toggle.
    //   - host-only (no domain), path `/`: set by the previous `g x` shortcut.
    // Remove both so disabling Next reliably clears the cookie.
    removeCookie(GITLAB_NEXT_COOKIE, COOKIE_OPTIONS);
    removeCookie(GITLAB_NEXT_COOKIE, { path: '/' });
  }
};

import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import OAuthDomainMismatchError from './components/oauth_domain_mismatch_error.vue';
import { parseCallbackUrls, getOAuthCallbackUrl } from './lib/gitlab_web_ide/oauth_callback_urls';

/**
 * Makes sure that we don't display the oauth mismatch error
 * based on case sensitive issues in the domain name.
 * @param {String} url
 */
const normalizeURL = (url) => {
  try {
    return new URL(url).toString();
  } catch {
    return url;
  }
};

export class OAuthCallbackDomainMismatchErrorApp {
  #el;
  #callbackUrls;
  #expectedCallbackUrl;

  constructor(el) {
    this.#el = el;
    this.#callbackUrls = parseCallbackUrls(el.dataset.callbackUrls);
    this.#expectedCallbackUrl = getOAuthCallbackUrl();
  }

  shouldRenderError() {
    if (!this.#callbackUrls.length) {
      return false;
    }

    return this.#callbackUrls.every(({ url }) => normalizeURL(url) !== this.#expectedCallbackUrl);
  }

  renderError() {
    const callbackUrls = this.#callbackUrls;
    const expectedCallbackUrl = this.#expectedCallbackUrl;
    const el = this.#el;

    if (!el) return null;

    return initVueApp({
      el,
      name: 'OAuthDomainMismatchErrorRoot',
      component: OAuthDomainMismatchError,
      props: {
        expectedCallbackUrl,
        callbackUrls,
      },
    });
  }
}

import Vue from 'vue';
import OAuthDomainMismatchError from './components/oauth_domain_mismatch_error.vue';

export class OAuthCallbackDomainMismatchErrorApp {
  #el;
  #callbackUrlOrigins;

  constructor(el, callbackUrls) {
    this.#el = el;
    this.#callbackUrlOrigins =
      OAuthCallbackDomainMismatchErrorApp.#getCallbackUrlOrigins(callbackUrls);
  }

  isVisitingFromNonRegisteredOrigin() {
    return (
      this.#callbackUrlOrigins.length && !this.#callbackUrlOrigins.includes(window.location.origin)
    );
  }

  renderError() {
    const callbackUrlOrigins = this.#callbackUrlOrigins;
    const el = this.#el;

    if (!el) return null;

    return new Vue({
      el,
      data() {
        return {
          callbackUrlOrigins,
        };
      },
      render(createElement) {
        return createElement(OAuthDomainMismatchError, {
          props: {
            callbackUrlOrigins,
          },
        });
      },
    });
  }

  static #getCallbackUrlOrigins(callbackUrls) {
    if (!callbackUrls) return [];

    return JSON.parse(callbackUrls).map((url) => new URL(url).origin);
  }
}

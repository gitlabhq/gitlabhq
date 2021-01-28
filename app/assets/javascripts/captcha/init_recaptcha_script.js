// NOTE: This module will be used in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/52044
import { memoize } from 'lodash';

export const RECAPTCHA_API_URL_PREFIX = 'https://www.google.com/recaptcha/api.js';
/**
 * The name which will be used for the reCAPTCHA script's onload callback
 */
export const RECAPTCHA_ONLOAD_CALLBACK_NAME = 'recaptchaOnloadCallback';

/**
 * Adds the Google reCAPTCHA script tag to the head of the document, and
 * returns a promise of the grecaptcha object
 * (https://developers.google.com/recaptcha/docs/display#js_api).
 *
 * It is memoized, so there will only be one instance of the script tag ever
 * added to the document.
 *
 * See the reCAPTCHA documentation for more details:
 *
 * https://developers.google.com/recaptcha/docs/display#explicit_render
 *
 */
export const initRecaptchaScript = memoize(() => {
  /**
   * Appends the the reCAPTCHA script tag to the head of document
   */
  const appendRecaptchaScript = () => {
    const script = document.createElement('script');
    script.src = `${RECAPTCHA_API_URL_PREFIX}?onload=${RECAPTCHA_ONLOAD_CALLBACK_NAME}&render=explicit`;
    script.classList.add('js-recaptcha-script');
    document.head.appendChild(script);
  };

  /**
   * Returns a Promise which is fulfilled after the reCAPTCHA script is loaded
   */
  return new Promise((resolve) => {
    window[RECAPTCHA_ONLOAD_CALLBACK_NAME] = resolve;
    appendRecaptchaScript();
  });
});

/**
 * Clears the cached memoization of the default manager.
 *
 * This is needed for determinism in tests.
 */
export const clearMemoizeCache = () => {
  initRecaptchaScript.cache.clear();
};

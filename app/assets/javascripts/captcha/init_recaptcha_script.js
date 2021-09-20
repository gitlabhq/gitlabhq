// NOTE: This module will be used in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/52044
import { memoize } from 'lodash';

export const RECAPTCHA_API_URL_PREFIX = window.gon.recaptcha_api_server_url;
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
  // Appends the the reCAPTCHA script tag to the head of document
  const appendRecaptchaScript = () => {
    const script = document.createElement('script');
    script.src = `${RECAPTCHA_API_URL_PREFIX}?onload=${RECAPTCHA_ONLOAD_CALLBACK_NAME}&render=explicit`;
    script.classList.add('js-recaptcha-script');
    document.head.appendChild(script);
  };

  return new Promise((resolve) => {
    // This global callback resolves the Promise and is passed by name to the reCAPTCHA script.
    window[RECAPTCHA_ONLOAD_CALLBACK_NAME] = () => {
      // Let's clean up after ourselves. This is also important for testing, because `window` is NOT cleared between tests.
      // https://github.com/facebook/jest/issues/1224#issuecomment-444586798.
      delete window[RECAPTCHA_ONLOAD_CALLBACK_NAME];
      resolve(window.grecaptcha);
    };
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

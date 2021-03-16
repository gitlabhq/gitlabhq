import Vue from 'vue';
import CaptchaModal from '~/captcha/captcha_modal.vue';
import UnsolvedCaptchaError from '~/captcha/unsolved_captcha_error';

/**
 * Opens a Captcha Modal with provided captchaSiteKey.
 *
 * Returns a Promise which resolves if the captcha is solved correctly, and rejects
 * if the captcha process is aborted.
 *
 * @param captchaSiteKey
 * @returns {Promise}
 */
export function waitForCaptchaToBeSolved(captchaSiteKey) {
  return new Promise((resolve, reject) => {
    let captchaModalElement = document.createElement('div');

    document.body.append(captchaModalElement);

    let captchaModalVueInstance = new Vue({
      el: captchaModalElement,
      render: (createElement) => {
        return createElement(CaptchaModal, {
          props: {
            captchaSiteKey,
            needsCaptchaResponse: true,
          },
          on: {
            hidden: () => {
              // Cleaning up the modal from the DOM
              captchaModalVueInstance.$destroy();
              captchaModalVueInstance.$el.remove();
              captchaModalElement.remove();

              captchaModalElement = null;
              captchaModalVueInstance = null;
            },
            receivedCaptchaResponse: (captchaResponse) => {
              if (captchaResponse) {
                resolve(captchaResponse);
              } else {
                // reject the promise with a custom exception, allowing consuming apps to
                // adjust their error handling, if appropriate.
                const error = new UnsolvedCaptchaError();
                reject(error);
              }
            },
          },
        });
      },
    });
  });
}

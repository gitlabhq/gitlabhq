import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import EmailVerification from './components/email_verification.vue';

export default () => {
  const el = document.querySelector('.js-email-verification');

  if (!el) {
    return null;
  }

  const { username, obfuscatedEmail, verifyPath, resendPath, offerEmailReset, updateEmailPath } =
    el.dataset;

  return new Vue({
    el,
    name: 'EmailVerificationRoot',
    provide: { updateEmailPath },
    render(createElement) {
      return createElement(EmailVerification, {
        props: {
          username,
          obfuscatedEmail,
          verifyPath,
          resendPath,
          isOfferEmailReset: parseBoolean(offerEmailReset),
        },
      });
    },
  });
};

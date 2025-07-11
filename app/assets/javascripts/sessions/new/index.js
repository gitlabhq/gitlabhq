import Vue from 'vue';
import EmailVerification from './components/email_verification.vue';

export default () => {
  const el = document.querySelector('.js-email-verification');

  if (!el) {
    return null;
  }

  const { username, obfuscatedEmail, verifyPath, resendPath } = el.dataset;

  return new Vue({
    el,
    name: 'EmailVerificationRoot',
    render(createElement) {
      return createElement(EmailVerification, {
        props: {
          username,
          obfuscatedEmail,
          verifyPath,
          resendPath,
        },
      });
    },
  });
};

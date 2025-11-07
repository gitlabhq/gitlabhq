import Vue from 'vue';
import EmailVerification from './components/email_verification.vue';
import TwoFactorEmailFallback from './components/two_factor_email_fallback.vue';

export default () => {
  const twoFactorFallbackElement = document.querySelector('#js-2fa-email-verification-data');

  if (twoFactorFallbackElement) {
    const { sendEmailOtpPath, username, emailVerificationData } = twoFactorFallbackElement.dataset;

    // Only mount if the 2FA form is actually visible
    const twoFaForm = document.querySelector('.js-2fa-form');
    const shouldMount = twoFaForm && !twoFaForm.classList.contains('hidden');

    if (shouldMount) {
      // eslint-disable-next-line no-new
      new Vue({
        el: twoFactorFallbackElement,
        name: 'TwoFactorEmailFallbackRoot',
        render(createElement) {
          return createElement(TwoFactorEmailFallback, {
            props: {
              sendEmailOtpPath,
              username,
              emailVerificationData: emailVerificationData && JSON.parse(emailVerificationData),
            },
          });
        },
      });
    }
  }

  const emailVerificationElement = document.querySelector('.js-email-verification');

  if (!emailVerificationElement) {
    return null;
  }

  const { username, obfuscatedEmail, verifyPath, resendPath, skipPath } =
    emailVerificationElement.dataset;

  return new Vue({
    el: emailVerificationElement,
    name: 'EmailVerificationRoot',
    render(createElement) {
      return createElement(EmailVerification, {
        props: {
          username,
          obfuscatedEmail,
          verifyPath,
          resendPath,
          skipPath,
        },
      });
    },
  });
};

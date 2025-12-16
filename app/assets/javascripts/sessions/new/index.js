import Vue from 'vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import EmailVerification from './components/email_verification.vue';
import TwoFactorEmailFallback from './components/two_factor_email_fallback.vue';

export const initTwoFactorEmailOTP = () => {
  const twoFactorFallbackElement = document.querySelector('#js-2fa-email-verification-data');

  if (!twoFactorFallbackElement) {
    return null;
  }

  const { sendEmailOtpPath, username, emailVerificationData } = twoFactorFallbackElement.dataset;

  return new Vue({
    el: twoFactorFallbackElement,
    name: 'TwoFactorEmailFallbackRoot',
    render(createElement) {
      const parsedEmailVerificationData =
        emailVerificationData && convertObjectPropsToCamelCase(JSON.parse(emailVerificationData));

      return createElement(TwoFactorEmailFallback, {
        props: {
          sendEmailOtpPath,
          username,
          emailVerificationData: parsedEmailVerificationData,
        },
      });
    },
  });
};

export const initEmailVerification = () => {
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

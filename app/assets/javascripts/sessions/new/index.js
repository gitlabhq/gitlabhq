import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import EmailVerification from './components/email_verification.vue';
import TwoFactorEmailFallback from './components/two_factor_email_fallback.vue';

export const initTwoFactorEmailOTP = () => {
  const twoFactorFallbackElement = document.querySelector('#js-2fa-email-verification-data');

  if (!twoFactorFallbackElement) {
    return null;
  }

  const { sendEmailOtpPath, username, emailVerificationData } = twoFactorFallbackElement.dataset;

  const parsedEmailVerificationData =
    emailVerificationData && convertObjectPropsToCamelCase(JSON.parse(emailVerificationData));

  return initVueApp({
    el: twoFactorFallbackElement,
    name: 'TwoFactorEmailFallbackRoot',
    component: TwoFactorEmailFallback,
    props: {
      sendEmailOtpPath,
      username,
      emailVerificationData: parsedEmailVerificationData,
    },
  });
};

export const initEmailVerification = () => {
  const emailVerificationElement = document.querySelector('.js-email-verification');

  if (!emailVerificationElement) {
    return null;
  }

  const { username, obfuscatedEmail, verifyPath, resendPath, skipPath, showResendAfter } =
    emailVerificationElement.dataset;

  return initVueApp({
    el: emailVerificationElement,
    name: 'EmailVerificationRoot',
    component: EmailVerification,
    props: {
      username,
      obfuscatedEmail,
      verifyPath,
      resendPath,
      skipPath,
      initialShowResendAfter: showResendAfter ? Number(showResendAfter) : null,
    },
  });
};

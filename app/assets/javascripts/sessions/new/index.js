import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import EmailVerification from './components/email_verification.vue';

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

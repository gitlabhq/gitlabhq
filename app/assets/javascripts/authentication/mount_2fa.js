import Vue from 'vue';
import { parseBoolean, convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import TwoFactorAuthentication from './sessions/components/two_factor_authentication.vue';
import { initWebauthnAuthenticate } from './webauthn';

export const mount2faAuthentication = () => {
  const el = document.getElementById('js-2fa');

  if (!el) {
    initWebauthnAuthenticate(); // remove when two_factor_vue flag is deleted.
    return false;
  }
  const {
    path,
    adminMode,
    activeMethod,
    rememberMe,
    rememberMeEnabled,
    webauthnEnabled,
    totpEnabled,
    emailEnabled,
    sendEmailOtpPath,
    emailVerificationData,
  } = el.dataset;

  return new Vue({
    el,
    name: 'TwoFactorAuthenticationRoot',
    render(createElement) {
      const parsedEmailVerificationData =
        emailVerificationData && convertObjectPropsToCamelCase(JSON.parse(emailVerificationData));

      return createElement(TwoFactorAuthentication, {
        props: {
          path,
          adminMode: parseBoolean(adminMode),
          activeMethod,
          rememberMe,
          rememberMeEnabled: parseBoolean(rememberMeEnabled),
          webauthnEnabled: parseBoolean(webauthnEnabled),
          totpEnabled: parseBoolean(totpEnabled),
          emailEnabled: parseBoolean(emailEnabled),
          sendEmailOtpPath,
          emailVerificationData: parsedEmailVerificationData,
          webauthnParams: gon.webauthn ? JSON.parse(gon.webauthn.options) : {},
        },
      });
    },
  });
};

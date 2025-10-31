import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import WebAuthnAuthenticate from './components/authenticate.vue';

export const initWebauthnAuthenticate = () => {
  const el = document.getElementById('js-authentication-webauthn');

  if (!el) {
    return false;
  }

  const {
    targetPath,
    renderRememberMe,
    rememberMe,
    sendEmailOtpPath,
    username,
    emailVerificationData,
  } = el.dataset;

  return new Vue({
    el,
    name: 'WebAuthnRoot',
    render(createElement) {
      return createElement(WebAuthnAuthenticate, {
        props: {
          webauthnParams: JSON.parse(gon.webauthn.options),
          targetPath,
          renderRememberMe: parseBoolean(renderRememberMe),
          rememberMe,
          sendEmailOtpPath,
          username,
          emailVerificationData: emailVerificationData && JSON.parse(emailVerificationData),
        },
      });
    },
  });
};

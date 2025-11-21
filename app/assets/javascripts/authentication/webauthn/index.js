import Vue from 'vue';
import { convertObjectPropsToCamelCase, parseBoolean } from '~/lib/utils/common_utils';
import WebAuthnAuthenticate from './components/authenticate.vue';
import PasskeyAuthentication from './components/passkey_authentication.vue';

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
          emailVerificationData:
            emailVerificationData &&
            convertObjectPropsToCamelCase(JSON.parse(emailVerificationData)),
        },
      });
    },
  });
};

export const initPasskeyAuthentication = () => {
  const el = document.getElementById('js-passkey-authentication');

  if (!el) {
    return false;
  }

  const { path, rememberMe, signInPath } = el.dataset;

  return new Vue({
    el,
    name: 'PasskeyRoot',
    render(createElement) {
      return createElement(PasskeyAuthentication, {
        props: {
          path,
          rememberMe,
          signInPath,
          webauthnParams: JSON.parse(gon.webauthn.options),
        },
      });
    },
  });
};

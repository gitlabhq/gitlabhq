import Vue from 'vue';
import $ from 'jquery';
import { parseBoolean } from '~/lib/utils/common_utils';
import WebAuthnAuthenticate from './authenticate';
import WebAuthnAuthenticateVue from './components/authenticate.vue';

const initLegacyWebauthnAuthenticate = () => {
  const el = $('#js-authenticate-token-2fa');

  if (!el.length) {
    return;
  }

  const webauthnAuthenticate = new WebAuthnAuthenticate(
    el,
    '#js-login-token-2fa-form',
    gon.webauthn,
    document.querySelector('#js-login-2fa-device'),
    document.querySelector('.js-2fa-form'),
  );
  webauthnAuthenticate.start();
};

const initVueWebauthnAuthenticate = () => {
  const el = document.getElementById('js-authentication-webauthn');

  if (!el) {
    return false;
  }

  const { targetPath, renderRememberMe, rememberMe } = el.dataset;

  return new Vue({
    el,
    name: 'WebAuthnRoot',
    render(createElement) {
      return createElement(WebAuthnAuthenticateVue, {
        props: {
          webauthnParams: JSON.parse(gon.webauthn.options),
          targetPath,
          renderRememberMe: parseBoolean(renderRememberMe),
          rememberMe,
        },
      });
    },
  });
};

export const initWebauthnAuthenticate = () => {
  if (!gon.webauthn) {
    return;
  }

  initLegacyWebauthnAuthenticate();
  initVueWebauthnAuthenticate();
};

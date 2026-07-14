import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
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
  } = el.dataset;

  return new Vue({
    el,
    name: 'TwoFactorAuthenticationRoot',
    render(createElement) {
      return createElement(TwoFactorAuthentication, {
        props: {
          path,
          adminMode: parseBoolean(adminMode),
          activeMethod,
          rememberMe,
          rememberMeEnabled: parseBoolean(rememberMeEnabled),
          webauthnEnabled: parseBoolean(webauthnEnabled),
          totpEnabled: parseBoolean(totpEnabled),
          webauthnParams: gon.webauthn ? JSON.parse(gon.webauthn.options) : {},
        },
      });
    },
  });
};

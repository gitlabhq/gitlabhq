import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import WebAuthnRegistration from './components/registration.vue';
import PasskeyRegistration from './components/passkey_registration.vue';

export const initWebAuthnRegistration = () => {
  const el = document.getElementById('js-device-registration');

  if (!el) {
    return null;
  }

  const { initialError, passwordRequired, targetPath } = el.dataset;

  return new Vue({
    el,
    name: 'WebAuthnRegistrationRoot',
    provide: { initialError, passwordRequired: parseBoolean(passwordRequired), targetPath },
    render(h) {
      return h(WebAuthnRegistration);
    },
  });
};

export const initPasskeyRegistration = () => {
  const el = document.getElementById('js-passkey-registration');

  if (!el) {
    return null;
  }

  const { initialError, passwordRequired, targetPath, twoFactorAuthPath } = el.dataset;

  return new Vue({
    el,
    name: 'PasskeyRegistrationRoot',
    provide: {
      initialError,
      passwordRequired: parseBoolean(passwordRequired),
      path: targetPath,
      twoFactorAuthPath,
    },
    render(h) {
      return h(PasskeyRegistration);
    },
  });
};

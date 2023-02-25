import Vue from 'vue';
import WebAuthnRegistration from '~/authentication/webauthn/components/registration.vue';
import { parseBoolean } from '~/lib/utils/common_utils';

export const initWebAuthnRegistration = () => {
  const el = document.querySelector('#js-device-registration');

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

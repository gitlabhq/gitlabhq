import Vue from 'vue';
import { s__ } from '~/locale';
import PasskeyAuthentication from './components/passkey_authentication.vue';
import SessionExpireModal from './components/session_expire_modal.vue';

export const initPasskeyAuthentication = () => {
  const el = document.getElementById('js-passkey-authentication');

  if (!el) {
    return false;
  }

  const { path, rememberMe } = el.dataset;

  return new Vue({
    el,
    name: 'PasskeyRoot',
    render(createElement) {
      return createElement(PasskeyAuthentication, {
        props: {
          path,
          rememberMe,
          webauthnParams: JSON.parse(gon.webauthn.options),
        },
      });
    },
  });
};

export const initExpireSessionModal = () => {
  const el = document.getElementById('js-session-expire-modal');

  if (!el) return null;

  const { sessionTimeout, signInUrl } = el.dataset;
  const message = s__(
    'SessionExpire|Please, sign in again. To avoid data loss, if you have unsaved edits, dismiss the modal and copy the unsaved text before sign in again.',
  );
  const title = s__('SessionExpire|Your session has expired');
  return new Vue({
    el,
    name: 'SessionExpireModalRoot',
    render: (createElement) =>
      createElement(SessionExpireModal, {
        props: {
          message,
          sessionTimeout: parseInt(sessionTimeout, 10),
          signInUrl,
          title,
        },
      }),
  });
};

import Vue from 'vue';
import { s__ } from '~/locale';
import SessionExpireModal from './components/session_expire_modal.vue';

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

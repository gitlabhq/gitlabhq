import Vue from 'vue';

import { initAdminUsersApp } from '~/admin/users';
import initConfirmModal from '~/confirm_modal';
import csrf from '~/lib/utils/csrf';
import Translate from '~/vue_shared/translate';
import ModalManager from './components/user_modal_manager.vue';

const CONFIRM_DELETE_BUTTON_SELECTOR = '.js-delete-user-modal-button';
const MODAL_TEXTS_CONTAINER_SELECTOR = '#js-modal-texts';
const MODAL_MANAGER_SELECTOR = '#js-delete-user-modal';

function loadModalsConfigurationFromHtml(modalsElement) {
  const modalsConfiguration = {};

  if (!modalsElement) {
    /* eslint-disable-next-line @gitlab/require-i18n-strings */
    throw new Error('Modals content element not found!');
  }

  Array.from(modalsElement.children).forEach((node) => {
    const { modal, ...config } = node.dataset;
    modalsConfiguration[modal] = {
      title: node.dataset.title,
      ...config,
      content: node.innerHTML,
    };
  });

  return modalsConfiguration;
}

document.addEventListener('DOMContentLoaded', () => {
  Vue.use(Translate);

  initAdminUsersApp();

  const modalConfiguration = loadModalsConfigurationFromHtml(
    document.querySelector(MODAL_TEXTS_CONTAINER_SELECTOR),
  );

  // eslint-disable-next-line no-new
  new Vue({
    el: MODAL_MANAGER_SELECTOR,
    functional: true,
    methods: {
      show(...args) {
        this.$refs.manager.show(...args);
      },
    },
    render(h) {
      return h(ModalManager, {
        ref: 'manager',
        props: {
          selector: CONFIRM_DELETE_BUTTON_SELECTOR,
          modalConfiguration,
          csrfToken: csrf.token,
        },
      });
    },
  });

  initConfirmModal();
});

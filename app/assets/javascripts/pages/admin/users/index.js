import Vue from 'vue';

import Translate from '~/vue_shared/translate';
import ModalManager from './components/user_modal_manager.vue';
import csrf from '~/lib/utils/csrf';
import initConfirmModal from '~/confirm_modal';
import { initAdminUsersApp, initCohortsEmptyState } from '~/admin/users';
import initTabs from '~/admin/users/tabs';

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
          modalConfiguration,
          csrfToken: csrf.token,
        },
      });
    },
  });

  initConfirmModal();
  initAdminUsersApp();
  initCohortsEmptyState();
  initTabs();
});

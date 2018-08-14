import $ from 'jquery';
import Vue from 'vue';

import Translate from '~/vue_shared/translate';
import csrf from '~/lib/utils/csrf';

import deleteUserModal from './components/delete_user_modal.vue';

document.addEventListener('DOMContentLoaded', () => {
  Vue.use(Translate);

  const deleteUserModalEl = document.getElementById('delete-user-modal');

  const deleteModal = new Vue({
    el: deleteUserModalEl,
    data: {
      deleteUserUrl: '',
      blockUserUrl: '',
      deleteContributions: '',
      username: '',
    },
    render(createElement) {
      return createElement(deleteUserModal, {
        props: {
          deleteUserUrl: this.deleteUserUrl,
          blockUserUrl: this.blockUserUrl,
          deleteContributions: this.deleteContributions,
          username: this.username,
          csrfToken: csrf.token,
        },
      });
    },
  });

  $(document).on('shown.bs.modal', (event) => {
    if (event.relatedTarget.classList.contains('delete-user-button')) {
      const buttonProps = event.relatedTarget.dataset;
      deleteModal.deleteUserUrl = buttonProps.deleteUserUrl;
      deleteModal.blockUserUrl = buttonProps.blockUserUrl;
      deleteModal.deleteContributions = event.relatedTarget.hasAttribute('data-delete-contributions');
      deleteModal.username = buttonProps.username;
    }
  });
});

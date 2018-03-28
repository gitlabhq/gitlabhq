import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import updateUsername from './components/update_username.vue';
import deleteAccountModal from './components/delete_account_modal.vue';

export default () => {
  Vue.use(Translate);

  const updateUsernameElement = document.getElementById('update-username');
  // eslint-disable-next-line no-new
  new Vue({
    el: updateUsernameElement,
    components: {
      updateUsername,
    },
    render(createElement) {
      return createElement('update-username', {
        props: { ...updateUsernameElement.dataset },
      });
    },
  });

  const deleteAccountButton = document.getElementById('delete-account-button');
  const deleteAccountModalEl = document.getElementById('delete-account-modal');
  // eslint-disable-next-line no-new
  new Vue({
    el: deleteAccountModalEl,
    components: {
      deleteAccountModal,
    },
    mounted() {
      deleteAccountButton.classList.remove('disabled');
    },
    render(createElement) {
      return createElement('delete-account-modal', {
        props: {
          actionUrl: deleteAccountModalEl.dataset.actionUrl,
          confirmWithPassword: !!deleteAccountModalEl.dataset.confirmWithPassword,
          username: deleteAccountModalEl.dataset.username,
        },
      });
    },
  });
};

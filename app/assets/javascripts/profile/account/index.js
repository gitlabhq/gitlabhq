import Vue from 'vue';

import deleteAccountModal from './components/delete_account_modal.vue';

const deleteAccountModalEl = document.getElementById('delete-account-modal');
// eslint-disable-next-line no-new
new Vue({
  el: deleteAccountModalEl,
  components: {
    deleteAccountModal,
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

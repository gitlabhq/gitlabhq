import Vue from 'vue';
import { BV_SHOW_MODAL } from '~/lib/utils/constants';
import Translate from '~/vue_shared/translate';
import { parseBoolean } from '~/lib/utils/common_utils';
import DeleteAccountModal from './components/delete_account_modal.vue';
import UpdateUsername from './components/update_username.vue';

export default () => {
  Vue.use(Translate);

  const updateUsernameElement = document.getElementById('update-username');
  // eslint-disable-next-line no-new
  new Vue({
    el: updateUsernameElement,
    components: {
      UpdateUsername,
    },
    render(createElement) {
      return createElement('update-username', {
        props: { ...updateUsernameElement.dataset },
      });
    },
  });

  const deleteAccountButton = document.getElementById('delete-account-button');
  const deleteAccountModalEl = document.getElementById('delete-account-modal');
  const { actionUrl, confirmWithPassword, username, delayUserAccountSelfDeletion } =
    deleteAccountModalEl.dataset;

  return new Vue({
    el: deleteAccountModalEl,
    components: {
      DeleteAccountModal,
    },
    mounted() {
      deleteAccountButton.disabled = false;
      deleteAccountButton.addEventListener('click', () => {
        this.$root.$emit(BV_SHOW_MODAL, 'delete-account-modal', '#delete-account-button');
      });
    },
    render(createElement) {
      return createElement('delete-account-modal', {
        props: {
          actionUrl,
          confirmWithPassword: parseBoolean(confirmWithPassword),
          username,
          delayUserAccountSelfDeletion: parseBoolean(delayUserAccountSelfDeletion),
        },
      });
    },
  });
};

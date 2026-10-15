import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { parseBoolean } from '@gitlab/frontend-utils';
import { BV_SHOW_MODAL } from '~/lib/utils/constants';
import Translate from '~/vue_shared/translate';
import createDefaultClient from '~/lib/graphql';
import DeleteAccountModal from './components/delete_account_modal.vue';
import ReassignedSourceUsers from './components/reassigned_source_users.vue';
import UpdateUsername from './components/update_username.vue';

Vue.use(Translate);
Vue.use(VueApollo);

const initUpdateUsername = () => {
  const updateUsernameElement = document.getElementById('update-username');

  if (!updateUsernameElement) {
    return false;
  }

  return new Vue({
    el: updateUsernameElement,
    name: 'UpdateUsernameRoot',
    components: {
      UpdateUsername,
    },
    render(createElement) {
      return createElement('update-username', {
        props: { ...updateUsernameElement.dataset },
      });
    },
  });
};

const initDeleteAccountModal = () => {
  const deleteAccountButton = document.getElementById('delete-account-button');
  const deleteAccountModalEl = document.getElementById('delete-account-modal');

  if (!deleteAccountButton || !deleteAccountModalEl) {
    return false;
  }

  const { actionUrl, confirmWithPassword, username, delayUserAccountSelfDeletion } =
    deleteAccountModalEl.dataset;

  return new Vue({
    el: deleteAccountModalEl,
    name: 'DeleteAccountModalRoot',
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

const initReassignedSourceUsers = () => {
  const el = document.getElementById('js-reassigned-source-users');

  if (!el) {
    return false;
  }

  return new Vue({
    el,
    name: 'ReassignedSourceUsersRoot',
    apolloProvider: new VueApollo({
      defaultClient: createDefaultClient(),
    }),
    render(createElement) {
      return createElement(ReassignedSourceUsers);
    },
  });
};

export default () => {
  initUpdateUsername();
  initDeleteAccountModal();
  initReassignedSourceUsers();
};

import Vue from 'vue';
import BindInOut from '~/behaviors/bind_in_out';
import initFilePickers from '~/file_pickers';
import Group from '~/group';
import { parseBoolean } from '~/lib/utils/common_utils';
import NewGroupCreationApp from './components/app.vue';
import GroupPathValidator from './group_path_validator';
import initToggleInviteMembers from './toggle_invite_members';

new GroupPathValidator(); // eslint-disable-line no-new

BindInOut.initAll();
initFilePickers();

new Group(); // eslint-disable-line no-new

function initNewGroupCreation(el) {
  const { hasErrors, verificationRequired, verificationFormUrl, subscriptionsUrl } = el.dataset;

  const props = {
    hasErrors: parseBoolean(hasErrors),
  };

  return new Vue({
    el,
    provide: {
      verificationRequired: parseBoolean(verificationRequired),
      verificationFormUrl,
      subscriptionsUrl,
    },
    render(h) {
      return h(NewGroupCreationApp, { props });
    },
  });
}

const el = document.querySelector('.js-new-group-creation');

initNewGroupCreation(el);

initToggleInviteMembers();

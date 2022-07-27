import Vue from 'vue';
import BindInOut from '~/behaviors/bind_in_out';
import initFilePickers from '~/file_pickers';
import Group from '~/group';
import { initGroupNameAndPath } from '~/groups/create_edit_form';
import { parseBoolean } from '~/lib/utils/common_utils';
import NewGroupCreationApp from './components/app.vue';
import GroupPathValidator from './group_path_validator';
import initToggleInviteMembers from './toggle_invite_members';

new GroupPathValidator(); // eslint-disable-line no-new
new Group(); // eslint-disable-line no-new
initGroupNameAndPath();

BindInOut.initAll();
initFilePickers();

function initNewGroupCreation(el) {
  const {
    hasErrors,
    parentGroupName,
    importExistingGroupPath,
    verificationRequired,
    verificationFormUrl,
    subscriptionsUrl,
  } = el.dataset;

  const props = {
    parentGroupName,
    importExistingGroupPath,
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

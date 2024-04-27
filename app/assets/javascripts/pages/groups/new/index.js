import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import BindInOut from '~/behaviors/bind_in_out';
import initFilePickers from '~/file_pickers';
import Group from '~/group';
import { initGroupNameAndPath } from '~/groups/create_edit_form';
import { parseBoolean } from '~/lib/utils/common_utils';
import NewGroupCreationApp from './components/app.vue';
import GroupPathValidator from './group_path_validator';
import initToggleInviteMembers from './toggle_invite_members';

Vue.use(VueApollo);

new GroupPathValidator(); // eslint-disable-line no-new
new Group(); // eslint-disable-line no-new
initGroupNameAndPath();

BindInOut.initAll();
initFilePickers();

function initNewGroupCreation(el) {
  const {
    hasErrors,
    rootPath,
    groupsUrl,
    parentGroupUrl,
    parentGroupName,
    importExistingGroupPath,
    isSaas,
    identityVerificationRequired,
    identityVerificationPath,
  } = el.dataset;

  const props = {
    groupsUrl,
    rootPath,
    parentGroupUrl,
    parentGroupName,
    importExistingGroupPath,
    hasErrors: parseBoolean(hasErrors),
    isSaas: parseBoolean(isSaas),
  };

  const provide = {
    identityVerificationRequired: parseBoolean(identityVerificationRequired),
    identityVerificationPath,
  };

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el,
    apolloProvider,
    provide,
    render(h) {
      return h(NewGroupCreationApp, { props });
    },
  });
}

const el = document.querySelector('.js-new-group-creation');

initNewGroupCreation(el);

initToggleInviteMembers();

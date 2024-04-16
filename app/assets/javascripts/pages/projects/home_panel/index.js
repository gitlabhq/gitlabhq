import { GlToast } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';

import { parseBoolean } from '~/lib/utils/common_utils';
import HomePanel from './components/home_panel.vue';

Vue.use(GlToast);
Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

const initHomePanel = () => {
  const container = document.getElementById('js-home-panel');

  if (container === null) {
    return null;
  }

  const {
    // HomePanel component
    adminPath,
    canReadProject,
    isProjectEmpty,
    projectId,

    // Dropdown component
    isGroup,
    leaveConfirmMessage,
    leavePath,
    requestAccessPath,
    withdrawConfirmMessage,
    withdrawPath,
    canEdit,
    editPath,

    // Fork component
    canCreateFork,
    canForkProject,
    canReadCode,
    forksCount,
    newForkUrl,
    projectForksUrl,
    projectFullPath,
    userForkUrl,

    // Notification component
    emailsDisabled,
    notificationDropdownItems,
    notificationHelpPagePath,
    notificationLevel,

    // Star component
    signInPath,
    starCount,
    starred,
    starrersPath,
  } = container.dataset;

  return new Vue({
    apolloProvider,
    el: container,
    name: 'HomePanelRoot',
    provide: {
      // HomePanel component
      adminPath,
      canReadProject: parseBoolean(canReadProject),
      isProjectEmpty: parseBoolean(isProjectEmpty),
      projectId,

      // Dropdown component
      groupOrProjectId: projectId,
      isGroup: parseBoolean(isGroup),
      leaveConfirmMessage,
      leavePath,
      requestAccessPath,
      withdrawConfirmMessage,
      withdrawPath,
      canEdit: parseBoolean(canEdit),
      editPath,

      // Fork component
      canCreateFork: parseBoolean(canCreateFork),
      canForkProject: parseBoolean(canForkProject),
      canReadCode: parseBoolean(canReadCode),
      forksCount: parseInt(forksCount, 10) || 0,
      newForkUrl,
      projectForksUrl,
      projectFullPath,
      userForkUrl,

      // Notification component
      dropdownItems: JSON.parse(notificationDropdownItems || null),
      emailsDisabled: parseBoolean(emailsDisabled),
      helpPagePath: notificationHelpPagePath,
      initialNotificationLevel: notificationLevel,
      noFlip: true,

      // Star component
      signInPath,
      starCount: parseInt(starCount, 10) || 0,
      starred: parseBoolean(starred),
      starrersPath,
    },
    render: (createElement) => createElement(HomePanel),
  });
};

export { initHomePanel };

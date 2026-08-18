import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import createDefaultClient from '~/lib/graphql';

import { parseBoolean } from '~/lib/utils/common_utils';
import HomePanelApp from './components/app.vue';

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
    projectAvatar,
    projectId,
    projectFullPath,

    // Dropdown component
    canRequestAccess,
    canWithdrawAccessRequest,
    requestAccessPath,
    withdrawAccessRequestPath,
    dashboardPath,

    // Fork component
    canForkProject,
    canReadCode,
    forksCount,
    newForkUrl,
    projectForksUrl,
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

    // Home Panel Heading
    projectName,
    projectVisibilityLevel,
    isProjectMarkedForDeletion,

    // Compliance Badge
    complianceFrameworkBadgeColor,
    complianceFrameworkBadgeName,
    complianceFrameworkBadgeTitle,
    hasComplianceFrameworkFeature,

    // CI/CD Catalogue Badge
    cicdCatalogPath,
  } = container.dataset;

  return initVueApp({
    apolloProvider,
    el: container,
    name: 'HomePanelRoot',
    provide: {
      // HomePanel component
      adminPath,
      canReadProject: parseBoolean(canReadProject),
      isProjectEmpty: parseBoolean(isProjectEmpty),
      projectAvatar,
      projectId: parseInt(projectId, 10),
      projectFullPath,

      // Dropdown component
      triggerDeleteLocation: 'header',
      triggerRestoreLocation: 'header',

      // Fork component
      canForkProject: parseBoolean(canForkProject),
      canReadCode: parseBoolean(canReadCode),
      forksCount: parseInt(forksCount, 10) || 0,
      newForkUrl,
      projectForksUrl,
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

      // Home Panel Heading
      projectName,
      projectVisibilityLevel,
      isProjectMarkedForDeletion: parseBoolean(isProjectMarkedForDeletion),

      // Compliance Badge
      complianceFrameworkBadgeColor,
      complianceFrameworkBadgeName,
      complianceFrameworkBadgeTitle,
      hasComplianceFrameworkFeature: parseBoolean(hasComplianceFrameworkFeature),

      // CI/CD Catalogue Badge
      cicdCatalogPath,
    },
    component: HomePanelApp,
    props: {
      canRequestAccess: parseBoolean(canRequestAccess),
      canWithdrawAccessRequest: parseBoolean(canWithdrawAccessRequest),
      requestAccessPath,
      withdrawAccessRequestPath,
      dashboardPath,
    },
  });
};

export { initHomePanel };

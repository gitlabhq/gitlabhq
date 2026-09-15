import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import VueApollo from 'vue-apollo';
import { parseDataAttributes } from '~/members/utils';
import { parseBoolean } from '~/lib/utils/common_utils';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import { TABS } from 'ee_else_ce/members/tabs_metadata';
import MembersTabs from './components/members_tabs.vue';
import membersStore from './store';
import { graphqlClient } from './graphql_client';
import { CONTEXT_TYPE } from './constants';

/**
 * @param {HTMLElement} el
 * @param {string} context as defined in CONTEXT_TYPE in ./constants.js
 * @param {Object} options
 */
export const initMembersApp = (el, context, options) => {
  if (!el) {
    return () => {};
  }

  Vue.use(Vuex);
  Vue.use(VueApollo);

  const {
    sourceId,
    canManageMembers,
    canManageAccessRequests,
    canExportMembers,
    canFilterByEnterprise,
    exportCsvPath,
    groupName,
    groupPath,
    projectPath,
    manageMemberRolesPath,
    canApproveAccessRequests,
    namespaceUserLimit,
    availableRoles,
    reassignmentCsvPath,
    restrictReassignmentToEnterprise,
    allowInactivePlaceholderReassignment,
    allowBypassPlaceholderConfirmation,
    ...vuexStoreAttributes
  } = parseDataAttributes(el);

  const modules = TABS.reduce((accumulator, tab) => {
    if (!options[tab.namespace]) {
      return accumulator;
    }
    const store = tab.store ?? membersStore;
    const data = vuexStoreAttributes[tab.namespace];
    const namespacedOptions = options[tab.namespace];
    const moduleStore = store({ ...data, ...namespacedOptions });

    return {
      ...accumulator,
      [tab.namespace]: moduleStore,
    };
  }, {});

  const store = new Vuex.Store({ modules });

  const isGroup = context === CONTEXT_TYPE.GROUP;
  const isProject = context === CONTEXT_TYPE.PROJECT;

  return initVueApp({
    el,
    name: 'MembersRoot',
    component: MembersTabs,
    store,
    apolloProvider: new VueApollo({
      defaultClient: graphqlClient,
    }),
    provide: {
      currentUserId: gon.current_user_id || null,
      sourceId,
      canManageMembers,
      canManageAccessRequests,
      canFilterByEnterprise,
      canExportMembers,
      exportCsvPath,
      manageMemberRolesPath,
      canApproveAccessRequests,
      namespaceUserLimit,
      availableRoles,
      context,
      reassignmentCsvPath,
      restrictReassignmentToEnterprise: parseBoolean(restrictReassignmentToEnterprise),
      allowInactivePlaceholderReassignment: parseBoolean(allowInactivePlaceholderReassignment),
      allowBypassPlaceholderConfirmation,
      group: {
        id: isGroup ? sourceId : null,
        name: groupName,
        path: groupPath,
      },
      project: {
        id: isProject ? sourceId : null,
        path: projectPath,
      },
    },
  });
};

import { GlToast } from '@gitlab/ui';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseDataAttributes } from '~/members/utils';
import { TABS } from 'ee_else_ce/members/tabs_metadata';
import MembersTabs from './components/members_tabs.vue';
import membersStore from './store';

export const initMembersApp = (el, options) => {
  if (!el) {
    return () => {};
  }

  Vue.use(Vuex);
  Vue.use(VueApollo);
  Vue.use(GlToast);

  const {
    sourceId,
    canManageMembers,
    canManageAccessRequests,
    canExportMembers,
    canFilterByEnterprise,
    exportCsvPath,
    groupName,
    groupPath,
    manageMemberRolesPath,
    canApproveAccessRequests,
    namespaceUserLimit,
    availableRoles,
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

  return new Vue({
    el,
    name: 'MembersRoot',
    components: { MembersTabs },
    store,
    apolloProvider: new VueApollo({ defaultClient: createDefaultClient() }),
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
      group: {
        name: groupName,
        path: groupPath,
      },
    },
    render: (createElement) => createElement('members-tabs'),
  });
};

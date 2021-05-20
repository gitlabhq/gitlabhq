import { GlToast } from '@gitlab/ui';
import Vue from 'vue';
import Vuex from 'vuex';
import { parseDataAttributes } from '~/members/utils';
import MembersTabs from './components/members_tabs.vue';
import { MEMBER_TYPES } from './constants';
import membersStore from './store';

export const initMembersApp = (el, options) => {
  if (!el) {
    return () => {};
  }

  Vue.use(Vuex);
  Vue.use(GlToast);

  const { sourceId, canManageMembers, ...vuexStoreAttributes } = parseDataAttributes(el);

  const modules = Object.keys(MEMBER_TYPES).reduce((accumulator, namespace) => {
    const namespacedOptions = options[namespace];

    if (!namespacedOptions) {
      return accumulator;
    }

    const {
      tableFields = [],
      tableAttrs = {},
      tableSortableFields = [],
      requestFormatter = () => {},
      filteredSearchBar = { show: false },
    } = namespacedOptions;

    return {
      ...accumulator,
      [namespace]: membersStore({
        ...vuexStoreAttributes[namespace],
        tableFields,
        tableAttrs,
        tableSortableFields,
        requestFormatter,
        filteredSearchBar,
      }),
    };
  }, {});

  const store = new Vuex.Store({ modules });

  return new Vue({
    el,
    components: { MembersTabs },
    store,
    provide: {
      currentUserId: gon.current_user_id || null,
      sourceId,
      canManageMembers,
    },
    render: (createElement) => createElement('members-tabs'),
  });
};

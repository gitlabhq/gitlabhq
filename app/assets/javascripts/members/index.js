import { GlToast } from '@gitlab/ui';
import Vue from 'vue';
import Vuex from 'vuex';
import { parseDataAttributes } from '~/members/utils';
import App from './components/app.vue';
import membersStore from './store';

export const initMembersApp = (
  el,
  {
    namespace,
    tableFields = [],
    tableAttrs = {},
    tableSortableFields = [],
    requestFormatter = () => {},
    filteredSearchBar = { show: false },
  },
) => {
  if (!el) {
    return () => {};
  }

  Vue.use(Vuex);
  Vue.use(GlToast);

  const { sourceId, canManageMembers, ...vuexStoreAttributes } = parseDataAttributes(el);

  const store = new Vuex.Store({
    modules: {
      [namespace]: membersStore({
        ...vuexStoreAttributes,
        tableFields,
        tableAttrs,
        tableSortableFields,
        requestFormatter,
        filteredSearchBar,
      }),
    },
  });

  return new Vue({
    el,
    components: { App },
    store,
    provide: {
      namespace,
      currentUserId: gon.current_user_id || null,
      sourceId,
      canManageMembers,
    },
    render: (createElement) => createElement('app'),
  });
};

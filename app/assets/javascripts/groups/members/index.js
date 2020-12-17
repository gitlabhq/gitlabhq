import Vue from 'vue';
import Vuex from 'vuex';
import { GlToast } from '@gitlab/ui';
import { parseDataAttributes } from 'ee_else_ce/groups/members/utils';
import App from './components/app.vue';
import membersStore from '~/members/store';

export const initGroupMembersApp = (
  el,
  {
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

  const store = new Vuex.Store(
    membersStore({
      ...parseDataAttributes(el),
      currentUserId: gon.current_user_id || null,
      tableFields,
      tableAttrs,
      tableSortableFields,
      requestFormatter,
      filteredSearchBar,
    }),
  );

  return new Vue({
    el,
    components: { App },
    store,
    render: createElement => createElement('app'),
  });
};

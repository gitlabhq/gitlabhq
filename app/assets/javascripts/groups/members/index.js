import Vue from 'vue';
import Vuex from 'vuex';
import { parseDataAttributes } from 'ee_else_ce/groups/members/utils';
import App from './components/app.vue';
import membersModule from '~/vuex_shared/modules/members';

export const initGroupMembersApp = (el, tableFields) => {
  if (!el) {
    return () => {};
  }

  Vue.use(Vuex);

  const store = new Vuex.Store({
    ...membersModule({
      ...parseDataAttributes(el),
      currentUserId: gon.current_user_id || null,
      tableFields,
    }),
  });

  return new Vue({
    el,
    components: { App },
    store,
    render: createElement => createElement('app'),
  });
};

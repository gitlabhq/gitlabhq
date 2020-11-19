import Vue from 'vue';
import Vuex from 'vuex';
import { GlToast } from '@gitlab/ui';
import { parseDataAttributes } from 'ee_else_ce/groups/members/utils';
import App from './components/app.vue';
import membersModule from '~/vuex_shared/modules/members';

export const initGroupMembersApp = (el, tableFields, tableAttrs, requestFormatter) => {
  if (!el) {
    return () => {};
  }

  Vue.use(Vuex);
  Vue.use(GlToast);

  const store = new Vuex.Store({
    ...membersModule({
      ...parseDataAttributes(el),
      currentUserId: gon.current_user_id || null,
      tableFields,
      tableAttrs,
      requestFormatter,
    }),
  });

  return new Vue({
    el,
    components: { App },
    store,
    render: createElement => createElement('app'),
  });
};

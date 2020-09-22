import Vue from 'vue';
import Vuex from 'vuex';
import App from './components/app.vue';
import membersModule from '~/vuex_shared/modules/members';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

export const initGroupMembersApp = (el, tableFields) => {
  if (!el) {
    return () => {};
  }

  Vue.use(Vuex);

  const { members, groupId } = el.dataset;

  const store = new Vuex.Store({
    ...membersModule({
      members: convertObjectPropsToCamelCase(JSON.parse(members), { deep: true }),
      sourceId: parseInt(groupId, 10),
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

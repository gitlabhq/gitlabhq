import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import UserList from '~/user_lists/components/user_list.vue';
import createStore from '~/user_lists/store/show';

Vue.use(Vuex);

export default function featureFlagsUserListInit() {
  const el = document.getElementById('js-edit-user-list');

  if (!el) {
    return null;
  }

  return new Vue({
    el,
    store: createStore(el.dataset),
    render(h) {
      const { emptyStatePath } = el.dataset;
      return h(UserList, { props: { emptyStatePath } });
    },
  });
}

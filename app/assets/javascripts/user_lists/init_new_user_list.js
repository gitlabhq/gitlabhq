import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import NewUserList from './components/new_user_list.vue';
import createStore from './store/new';

Vue.use(Vuex);

export const initNewUserList = () => {
  const el = document.getElementById('js-new-user-list');

  if (!el) {
    return null;
  }

  const { userListsDocsPath, featureFlagsPath } = el.dataset;

  return new Vue({
    el,
    name: 'FeatureFlagsNewUserListRoot',
    store: createStore(el.dataset),
    provide: {
      userListsDocsPath,
      featureFlagsPath,
    },
    render(h) {
      return h(NewUserList);
    },
  });
};

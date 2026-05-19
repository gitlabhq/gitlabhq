import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import UserLists from './components/user_lists.vue';
import createStore from './store/index';

Vue.use(Vuex);

export const initUserLists = () => {
  const el = document.querySelector('#js-user-lists');

  if (!el) {
    return null;
  }

  const { featureFlagsHelpPagePath, errorStateSvgPath, projectId, newUserListPath } = el.dataset;

  return new Vue({
    el,
    name: 'UserListsRoot',
    store: createStore({ projectId }),
    provide: {
      featureFlagsHelpPagePath,
      errorStateSvgPath,
      newUserListPath,
    },
    render(createElement) {
      return createElement(UserLists);
    },
  });
};

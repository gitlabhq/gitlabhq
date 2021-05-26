/* eslint-disable no-new */

import Vue from 'vue';
import Vuex from 'vuex';
import UserLists from '~/user_lists/components/user_lists.vue';
import createStore from '~/user_lists/store/index';

Vue.use(Vuex);

const el = document.querySelector('#js-user-lists');

const { featureFlagsHelpPagePath, errorStateSvgPath, projectId, newUserListPath } = el.dataset;

new Vue({
  el,
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

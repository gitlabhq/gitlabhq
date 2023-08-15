/* eslint-disable no-new */

import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import NewUserList from '~/user_lists/components/new_user_list.vue';
import createStore from '~/user_lists/store/new';

Vue.use(Vuex);

const el = document.getElementById('js-new-user-list');
const { userListsDocsPath, featureFlagsPath } = el.dataset;
new Vue({
  el,
  store: createStore(el.dataset),
  provide: {
    userListsDocsPath,
    featureFlagsPath,
  },
  render(h) {
    return h(NewUserList);
  },
});

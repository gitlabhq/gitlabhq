import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import * as actions from './actions';
import mutations from './mutations';

Vue.use(Vuex);

const createState = () => ({
  awards: [],
  awardPath: '',
  currentUserId: null,
  canAwardEmoji: false,
});

export default () =>
  new Vuex.Store({
    state: createState(),
    actions,
    mutations,
  });

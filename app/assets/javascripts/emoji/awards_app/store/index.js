import Vue from 'vue';
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

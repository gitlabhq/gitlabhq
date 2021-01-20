import Vuex from 'vuex';
import mutations from './mutations';
import state from './state';

export default () =>
  new Vuex.Store({
    state,
    mutations,
  });

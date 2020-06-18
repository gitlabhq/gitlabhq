import Vue from 'vue';
import Vuex from 'vuex';
import state from './state';
import * as actions from './actions';
import * as getters from './getters';
import mutations from './mutations';

Vue.use(Vuex);

export { state, actions, getters, mutations };

export default initialState =>
  new Vuex.Store({
    state: { ...state(), ...initialState },
    actions,
    mutations,
    getters,
  });

import Vuex from 'vuex';
import Vue from 'vue';
import createState from './state';
import * as getters from './getters';
import * as actions from './actions';
import mutations from './mutations';

Vue.use(Vuex);

const createStore = ({ initialState } = {}) => {
  return new Vuex.Store({
    state: createState(initialState),
    getters,
    actions,
    mutations,
  });
};

export default createStore;

import Vue from 'vue';
import Vuex from 'vuex';
import * as actions from './actions';
import mutations from './mutations';
import createState from './state';

Vue.use(Vuex);

export default function createStore(initialState) {
  return new Vuex.Store({
    mutations,
    actions,
    state: createState(initialState),
  });
}

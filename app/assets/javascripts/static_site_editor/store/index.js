import Vuex from 'vuex';
import Vue from 'vue';
import createState from './state';

Vue.use(Vuex);

const createStore = ({ initialState } = {}) => {
  return new Vuex.Store({
    state: createState(initialState),
  });
};

export default createStore;

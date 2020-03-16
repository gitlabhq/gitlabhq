import Vue from 'vue';
import Vuex from 'vuex';

Vue.use(Vuex);

export default ({ modules, featureFlags }) =>
  new Vuex.Store({
    modules,
    state: { featureFlags },
  });

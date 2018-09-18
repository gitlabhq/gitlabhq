import Vue from 'vue';
import Vuex from 'vuex';
import vulnerabilities from './modules/vulnerabilities/index';

Vue.use(Vuex);

export default () => new Vuex.Store({
  modules: {
    vulnerabilities,
  },
});

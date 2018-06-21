import Vue from 'vue';
import Vuex from 'vuex';
import diffsModule from './modules';

Vue.use(Vuex);

export default new Vuex.Store({
  modules: {
    diffs: diffsModule,
  },
});

import Vue from 'vue';
import Vuex from 'vuex';
import ReleaseIndexApp from './components/app_index.vue';
import createStore from './stores';
import createIndexModule from './stores/modules/index';

Vue.use(Vuex);

export default () => {
  const el = document.getElementById('js-releases-page');

  return new Vue({
    el,
    store: createStore({
      modules: {
        index: createIndexModule(el.dataset),
      },
    }),
    render: (h) => h(ReleaseIndexApp),
  });
};

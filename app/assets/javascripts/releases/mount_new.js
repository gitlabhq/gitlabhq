import Vue from 'vue';
import Vuex from 'vuex';
import ReleaseEditNewApp from './components/app_edit_new.vue';
import createStore from './stores';
import createDetailModule from './stores/modules/detail';

Vue.use(Vuex);

export default () => {
  const el = document.getElementById('js-new-release-page');

  const store = createStore({
    modules: {
      detail: createDetailModule(el.dataset),
    },
  });

  return new Vue({
    el,
    store,
    render: h => h(ReleaseEditNewApp),
  });
};

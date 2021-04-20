import Vue from 'vue';
import Vuex from 'vuex';
import ReleaseEditNewApp from './components/app_edit_new.vue';
import createStore from './stores';
import createEditNewModule from './stores/modules/edit_new';

Vue.use(Vuex);

export default () => {
  const el = document.getElementById('js-new-release-page');

  const store = createStore({
    modules: {
      editNew: createEditNewModule(el.dataset),
    },
  });

  return new Vue({
    el,
    store,
    render: (h) => h(ReleaseEditNewApp),
  });
};

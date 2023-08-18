import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import ReleaseEditNewApp from './components/app_edit_new.vue';
import createStore from './stores';
import createEditNewModule from './stores/modules/edit_new';

Vue.use(Vuex);

export default () => {
  const el = document.getElementById('js-edit-release-page');

  const store = createStore({
    modules: {
      editNew: createEditNewModule({ ...el.dataset, isExistingRelease: true }),
    },
  });

  return new Vue({
    el,
    store,
    render: (h) => h(ReleaseEditNewApp),
  });
};

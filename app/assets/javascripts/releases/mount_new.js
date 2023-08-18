import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { createRefModule } from '../ref/stores';
import ReleaseEditNewApp from './components/app_edit_new.vue';
import createStore from './stores';
import createEditNewModule from './stores/modules/edit_new';

Vue.use(Vuex);

export default () => {
  const el = document.getElementById('js-new-release-page');

  const store = createStore({
    modules: {
      editNew: createEditNewModule({ ...el.dataset, isExistingRelease: false }),
      ref: createRefModule(),
    },
  });

  return new Vue({
    el,
    store,
    render: (h) => h(ReleaseEditNewApp),
  });
};

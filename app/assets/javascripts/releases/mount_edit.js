import Vue from 'vue';
import ReleaseEditNewApp from './components/app_edit_new.vue';
import createStore from './stores';
import createDetailModule from './stores/modules/detail';

export default () => {
  const el = document.getElementById('js-edit-release-page');

  const store = createStore({
    modules: {
      detail: createDetailModule(el.dataset),
    },
    featureFlags: {
      releaseShowPage: Boolean(gon.features?.releaseShowPage),
    },
  });

  return new Vue({
    el,
    store,
    render: h => h(ReleaseEditNewApp),
  });
};

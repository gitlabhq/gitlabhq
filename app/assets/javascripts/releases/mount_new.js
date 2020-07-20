import Vue from 'vue';
import ReleaseNewApp from './components/app_new.vue';
import createStore from './stores';
import createDetailModule from './stores/modules/detail';

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
    render: h => h(ReleaseNewApp),
  });
};

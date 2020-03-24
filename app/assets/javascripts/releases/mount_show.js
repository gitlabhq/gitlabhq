import Vue from 'vue';
import ReleaseShowApp from './components/app_show.vue';
import createStore from './stores';
import createDetailModule from './stores/modules/detail';

export default () => {
  const el = document.getElementById('js-show-release-page');

  const store = createStore({
    modules: {
      detail: createDetailModule(el.dataset),
    },
  });

  return new Vue({
    el,
    store,
    render: h => h(ReleaseShowApp),
  });
};

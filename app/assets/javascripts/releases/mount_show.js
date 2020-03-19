import Vue from 'vue';
import ReleaseShowApp from './components/app_show.vue';
import createStore from './stores';
import detailModule from './stores/modules/detail';

export default () => {
  const el = document.getElementById('js-show-release-page');

  const store = createStore({
    modules: {
      detail: detailModule,
    },
  });
  store.dispatch('detail/setInitialState', el.dataset);

  return new Vue({
    el,
    store,
    render: h => h(ReleaseShowApp),
  });
};

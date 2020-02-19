import Vue from 'vue';
import ReleaseEditApp from './components/app_edit.vue';
import createStore from './stores';
import detailModule from './stores/modules/detail';

export default () => {
  const el = document.getElementById('js-edit-release-page');

  const store = createStore({ detail: detailModule });
  store.dispatch('detail/setInitialState', el.dataset);

  return new Vue({
    el,
    store,
    render: h => h(ReleaseEditApp),
  });
};

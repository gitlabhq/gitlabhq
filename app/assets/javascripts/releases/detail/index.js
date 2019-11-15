import Vue from 'vue';
import ReleaseDetailApp from './components/app.vue';
import createStore from './store';

export default () => {
  const el = document.getElementById('js-edit-release-page');

  const store = createStore();
  store.dispatch('setInitialState', el.dataset);

  return new Vue({
    el,
    store,
    components: { ReleaseDetailApp },
    render(createElement) {
      return createElement('release-detail-app');
    },
  });
};

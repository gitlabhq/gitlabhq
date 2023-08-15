import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import App from './components/app.vue';
import createStore from './store';

export default (initialData) => {
  const el = document.getElementById('js-code-navigation');

  if (!el) return null;

  Vue.use(Vuex);

  const store = createStore();

  store.dispatch('setInitialData', initialData);

  return new Vue({
    el,
    store,
    render(h) {
      return h(App);
    },
  });
};

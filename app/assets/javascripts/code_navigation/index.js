import Vue from 'vue';
import Vuex from 'vuex';
import createStore from './store';
import App from './components/app.vue';

export default initialData => {
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

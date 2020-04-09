import Vue from 'vue';
import Vuex from 'vuex';
import store from './store';
import App from './components/app.vue';

Vue.use(Vuex);

export default initialData => {
  const el = document.getElementById('js-code-navigation');

  store.dispatch('setInitialData', initialData);

  return new Vue({
    el,
    store,
    render(h) {
      return h(App);
    },
  });
};

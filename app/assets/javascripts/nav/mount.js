import Vue from 'vue';
import Vuex from 'vuex';
import App from './components/top_nav_app.vue';
import { createStore } from './stores';

Vue.use(Vuex);

export const mountTopNav = (el) => {
  const viewModel = JSON.parse(el.dataset.viewModel);
  const store = createStore();

  return new Vue({
    el,
    store,
    render(h) {
      return h(App, {
        props: {
          navData: viewModel,
        },
      });
    },
  });
};

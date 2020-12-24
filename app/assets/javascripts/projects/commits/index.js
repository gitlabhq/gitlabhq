import Vue from 'vue';
import Vuex from 'vuex';
import AuthorSelectApp from './components/author_select.vue';
import store from './store';

Vue.use(Vuex);

export default (el) => {
  if (!el) {
    return null;
  }

  store.dispatch('setInitialData', el.dataset);

  return new Vue({
    el,
    store,
    render(h) {
      return h(AuthorSelectApp, {
        props: {
          projectCommitsEl: document.querySelector('.js-project-commits-show'),
        },
      });
    },
  });
};

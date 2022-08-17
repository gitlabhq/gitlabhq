import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import HeaderSearchApp from './components/app.vue';
import createStore from './store';

Vue.use(Translate);

export const initHeaderSearchApp = (search = '') => {
  const el = document.getElementById('js-header-search');
  let navBarEl = null;

  if (!el) {
    return false;
  }

  const { searchPath, issuesPath, mrPath, autocompletePath } = el.dataset;
  let { searchContext } = el.dataset;
  searchContext = JSON.parse(searchContext);

  return new Vue({
    el,
    store: createStore({ searchPath, issuesPath, mrPath, autocompletePath, searchContext, search }),
    mounted() {
      navBarEl = document.querySelector('.header-content');
    },
    render(createElement) {
      return createElement(HeaderSearchApp, {
        on: {
          expandSearchBar: () => {
            navBarEl?.classList.add('header-search-is-active');
          },
          collapseSearchBar: () => {
            navBarEl?.classList.remove('header-search-is-active');
          },
        },
      });
    },
  });
};

import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import GlobalSearchSort from './components/app.vue';

Vue.use(Translate);

export const initSearchSort = (store) => {
  const el = document.getElementById('js-search-sort');

  if (!el) return false;

  let { searchSortOptions } = el.dataset;

  searchSortOptions = JSON.parse(searchSortOptions);

  return new Vue({
    el,
    store,
    render(createElement) {
      return createElement(GlobalSearchSort, {
        props: {
          searchSortOptions,
        },
      });
    },
  });
};

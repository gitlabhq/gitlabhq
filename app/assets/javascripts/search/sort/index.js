import Vue from 'vue';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import Translate from '~/vue_shared/translate';
import GlobalSearchSort from './components/app.vue';

Vue.use(Translate);

export const initSearchSort = (store) => {
  const el = document.getElementById('js-search-sort');

  if (!el) return false;

  let { searchSortOptions } = el.dataset;

  searchSortOptions = JSON.parse(searchSortOptions);

  return initVueApp({
    el,
    name: 'GlobalSearchSortRoot',
    store,
    component: GlobalSearchSort,
    props: {
      searchSortOptions,
    },
  });
};

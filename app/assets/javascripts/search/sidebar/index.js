import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import StatusFilter from './components/status_filter.vue';
import ConfidentialityFilter from './components/confidentiality_filter.vue';

Vue.use(Translate);

const mountRadioFilters = (store, { id, component }) => {
  const el = document.getElementById(id);

  if (!el) return false;

  return new Vue({
    el,
    store,
    render(createElement) {
      return createElement(component);
    },
  });
};

const radioFilters = [
  {
    id: 'js-search-filter-by-state',
    component: StatusFilter,
  },
  {
    id: 'js-search-filter-by-confidential',
    component: ConfidentialityFilter,
  },
];

export const initSidebar = store =>
  [...radioFilters].map(filter => mountRadioFilters(store, filter));

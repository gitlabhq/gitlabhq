import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import DropdownFilter from './components/dropdown_filter.vue';
import stateFilterData from './constants/state_filter_data';
import confidentialFilterData from './constants/confidential_filter_data';

Vue.use(Translate);

const mountDropdownFilter = (store, { id, filterData }) => {
  const el = document.getElementById(id);

  if (!el) return false;

  return new Vue({
    el,
    store,
    render(createElement) {
      return createElement(DropdownFilter, {
        props: {
          filterData,
        },
      });
    },
  });
};

const dropdownFilters = [
  {
    id: 'js-search-filter-by-state',
    filterData: stateFilterData,
  },
  {
    id: 'js-search-filter-by-confidential',
    filterData: confidentialFilterData,
  },
];

export default store => [...dropdownFilters].map(filter => mountDropdownFilter(store, filter));
